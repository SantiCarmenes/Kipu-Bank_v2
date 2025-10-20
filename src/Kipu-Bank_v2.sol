// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// -----------------------------------------------------------------------------------------------
///                                         IMPORTS
/// -----------------------------------------------------------------------------------------------

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title KipuBank - A simple bank with deposit and withdrawal limits
/// @author Santiago Carmenes
/// @notice This contract allows users to deposit and withdraw ETH with security limits
contract KipuBank is Ownable {

    /// -----------------------------------------------------------------------------------------------
    ///                                       LIBRARIES
    /// -----------------------------------------------------------------------------------------------
    
    using SafeERC20 for IERC20;


    /// -----------------------------------------------------------------------------------------------
    ///                                        CONSTANTS
    /// -----------------------------------------------------------------------------------------------
    
    /// @notice ETH address constant
    address public constant ETH_ADDRESS = address(0);

    /// @notice The maximum age of a price feed update (e.g., 1 hour)
    uint256 public constant ORACLE_HEARTBEAT = 3600;
    

    /// -----------------------------------------------------------------------------------------------
    ///                                    STATE VARIABLES
    /// -----------------------------------------------------------------------------------------------

    /// @notice Total ETH limit that can be stored in the bank
    /// @dev Chose to use uint256 since ERC20 tokens also use uint256 for amounts
    uint256 public immutable i_bankCap;

    /// @notice ETH limit that can be withdrawn in a single transaction
    uint256 public immutable i_withdrawLimit;

    /// @notice Total USD value stored in the bank
    uint256 public s_totalUsdValue;

    /// @notice Total number of historical deposits
    uint32 public s_totalDeposits;

    /// @notice Total number of historical withdrawals
    uint32 public s_totalWithdrawals;

    /// @notice Struct to hold all relevant information for a token
    struct TokenInfo {
        address priceFeed;
        uint8 decimals;
    }

    /// -----------------------------------------------------------------------------------------------
    ///                                        MAPPINGS
    /// -----------------------------------------------------------------------------------------------

    /// @notice User balances mapping
    /// @dev mapping(TokenAddress => mapping(UserAddress => Amount)) 
    mapping(address => mapping(address => uint256)) public s_balances;

    /// @notice Token information mapping
    /// @dev mapping(TokenAddress => TokenInfo)
    mapping(address => TokenInfo) public s_tokenInfo;


    /// -----------------------------------------------------------------------------------------------
    ///                                         EVENTS
    /// -----------------------------------------------------------------------------------------------

    /// @notice Emitted upon ETH deposit
    event Deposited(address indexed token, address indexed user, uint256 amount);

    /// @notice Emitted upon ETH withdrawal
    event Withdrawn(address indexed token, address indexed user, uint256 amount);

    /// @notice Emitted when a price feed is updated
    event PriceFeedUpdated(address indexed token, address indexed feed);


    /// -----------------------------------------------------------------------------------------------
    ///                                         ERRORS
    /// -----------------------------------------------------------------------------------------------

    error KipuBank__ExceedsBankCap(uint256 attempted, uint256 cap);
    error KipuBank__ExceedsWithdrawLimit(uint256 attempted, uint256 limit);
    error KipuBank__InsufficientBalance(address token, uint256 requested, uint256 available);
    error KipuBank__TransferFailed(address to, uint256 amount);
    error KipuBank__NotAToken();
    error KipuBank__AmountMustBeGreaterThanZero();
    error KipuBank__PriceFeedNotSet(address tokenAddress);
    error KipuBank__OracleCompromised();
    error KipuBank__StalePrice();


    /// -----------------------------------------------------------------------------------------------
    ///                                       CONSTRUCTOR
    /// -----------------------------------------------------------------------------------------------

    /// @notice Constructor to initialize bank cap and withdrawal limit
    /// @param _bankCap Total USD limit for the bank
    /// @param _withdrawLimit Maximum withdrawal limit per transaction
    constructor(uint256 _bankCap, uint256 _withdrawLimit) Ownable(msg.sender) {
        i_bankCap = _bankCap;
        i_withdrawLimit = _withdrawLimit;
    }


    /// -----------------------------------------------------------------------------------------------
    ///                                        MODIFIERS
    /// -----------------------------------------------------------------------------------------------

    /// @notice Ensures the deposit does not exceed the total bank cap
    modifier withinBankCap(address _tokenAddress, uint256 _amount) {
        uint256 incomingValue = getValueInUsd(_tokenAddress, _amount);
        
        if (s_totalUsdValue + incomingValue > i_bankCap) {
            revert KipuBank__ExceedsBankCap(s_totalUsdValue + incomingValue, i_bankCap);
        }
        _;
    }

    /// @notice Ensures the withdrawal does not exceed the per-transaction limit
    modifier withinWithdrawLimit(uint256 _amount) {
        if (_amount > i_withdrawLimit) {
            revert KipuBank__ExceedsWithdrawLimit(_amount, i_withdrawLimit);
        }
        _;
    }

    /// @notice Ensures the user has sufficient funds
    modifier hasSufficientBalance(address _tokenAddress, uint256 _amount) {
        if (_amount > s_balances[_tokenAddress][msg.sender]) {
            revert KipuBank__InsufficientBalance(_tokenAddress, _amount, s_balances[_tokenAddress][msg.sender]);
        }
        _;
    }

    /// @notice Ensures the amount is greater than zero
    modifier nonZeroAmount(uint256 _amount) {
        if (_amount == 0) {
            revert KipuBank__AmountMustBeGreaterThanZero();
        }
        _;
    }


    /// -----------------------------------------------------------------------------------------------
    ///                                    EXTERNAL FUNCTIONS
    /// -----------------------------------------------------------------------------------------------

    /// @notice Calls internal deposit function for ETH deposits
    /// @dev Uses withinBankCap modifier to enforce bank cap
    function deposit() external payable withinBankCap(ETH_ADDRESS, msg.value) {
        _deposit(ETH_ADDRESS, msg.sender, msg.value);
    }

    /// @notice Deposit ERC20 tokens into the bank
    /// @param _tokenAddress Address of the ERC20 token
    /// @param _amount Amount of tokens to deposit
    function depositToken(address _tokenAddress, uint256 _amount) external withinBankCap(_tokenAddress, _amount) {
        if (_tokenAddress == ETH_ADDRESS) {
            revert KipuBank__NotAToken();
        }
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_tokenAddress, msg.sender, _amount);
    }

    /// @notice Withdraw ETH from the bank
    /// @param _amount Amount of ETH to withdraw
    /// @dev Uses withinWithdrawLimit and hasSufficientBalance modifiers
    function withdraw(uint256 _amount) external withinWithdrawLimit(_amount) hasSufficientBalance(ETH_ADDRESS, _amount) {
        _withdraw(ETH_ADDRESS, msg.sender, _amount);
    }

    /// @notice Withdraw ERC20 tokens from the bank
    /// @param _tokenAddress Address of the ERC20 token
    /// @param _amount Amount of tokens to withdraw
    function withdrawToken(address _tokenAddress, uint256 _amount) external hasSufficientBalance(_tokenAddress, _amount) {
        if (_tokenAddress == ETH_ADDRESS) {
            revert KipuBank__NotAToken();
        }
        _withdraw(_tokenAddress, msg.sender, _amount);
    }

    /// @notice Check your own token balance
    /// @param _tokenAddress Address of the ERC20 token
    /// @return balance Amount of tokens available for the user
    function getMyBalance(address _tokenAddress) external view returns (uint256) {
        return s_balances[_tokenAddress][msg.sender];
    }

    /// @notice Check the total balance of the bank
    /// @return totalBalance Total ETH stored in the contract
    function getTotalEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Set the price feed address for a token
    /// @param _tokenAddress Address of the token
    function setPriceFeed(address _tokenAddress, address _priceFeedAddress) external onlyOwner {
        uint8 decimals;
        if (_tokenAddress == ETH_ADDRESS) {
            decimals = 18;
        } else {
            decimals = IERC20Metadata(_tokenAddress).decimals();
        }

        TokenInfo memory token = TokenInfo({priceFeed: _priceFeedAddress, decimals: decimals});
        s_tokenInfo[_tokenAddress] = token;
        
        emit PriceFeedUpdated(_tokenAddress, _priceFeedAddress);
    }


    /// -----------------------------------------------------------------------------------------------
    ///                                     PUBLIC FUNCTIONS
    /// -----------------------------------------------------------------------------------------------

    /// @notice Get value of a token amount in USD
    /// @param _tokenAddress Address of the token
    /// @param _amount Amount of tokens
    /// @return valueInUsd Value in USD with decimals
    function getValueInUsd(address _tokenAddress, uint256 _amount) public view returns (uint256) {
        TokenInfo memory token = s_tokenInfo[_tokenAddress];
        
        if (token.priceFeed == address(0)) {
            revert KipuBank__PriceFeedNotSet(_tokenAddress);
        }
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(token.priceFeed);
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();

        if (price <= 0) {
            revert KipuBank__OracleCompromised();
        }
        if (block.timestamp - updatedAt > ORACLE_HEARTBEAT) {
            revert KipuBank__StalePrice();
        }

        // Usamos los decimales leídos desde la struct
        return (_amount * uint256(price)) / (10**uint256(token.decimals));
    }


    /// -----------------------------------------------------------------------------------------------
    ///                                    INTERNAL FUNCTIONS
    /// -----------------------------------------------------------------------------------------------
    
    /// @notice Updates user balance upon deposit
    /// @param _tokenAddress Token address
    /// @param _user User address
    /// @param _amount Amount to deposit
    function _deposit(address _tokenAddress, address _user, uint256 _amount) internal nonZeroAmount(_amount) {
        s_balances[_tokenAddress][_user] += _amount;
        _updateCounters(true);

        uint256 value = getValueInUsd(_tokenAddress, _amount);
        s_totalUsdValue += value;

        emit Deposited(_tokenAddress, _user, _amount);
    }
    
    /// @notice Updates user balance upon withdrawal
    /// @param _tokenAddress Token address
    /// @param _user User address
    /// @param _amount Amount to withdraw
    function _withdraw(address _tokenAddress, address _user, uint256 _amount) internal nonZeroAmount(_amount) {
        s_balances[_tokenAddress][_user] -= _amount;
        _updateCounters(false);

        uint256 value = getValueInUsd(_tokenAddress, _amount);
        s_totalUsdValue -= value;

        if (_tokenAddress == ETH_ADDRESS) {
            _safeTransferEth(_user, _amount);
        } else {
            IERC20(_tokenAddress).safeTransfer(_user, _amount);
        }

        emit Withdrawn(_tokenAddress, _user, _amount);
    }


    /// -----------------------------------------------------------------------------------------------
    ///                                     PRIVATE FUNCTIONS
    /// -----------------------------------------------------------------------------------------------
    
    /// @notice Updates the deposit and withdrawal counters
    /// @param isDeposit True for deposit, false for withdrawal
    function _updateCounters(bool isDeposit) private {
        if (isDeposit) {
            s_totalDeposits += 1;
        } else {
            s_totalWithdrawals += 1;
        }
    }

    /// @notice Safe ETH transfer
    /// @param to Recipient's address
    /// @param amount ETH amount to send
    function _safeTransferEth(address to, uint256 amount) private {
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) {
            revert KipuBank__TransferFailed(to, amount);
        }
    }


    /// -----------------------------------------------------------------------------------------------
    ///                                 RECEIVE & FALLBACK FUNCTIONS
    /// -----------------------------------------------------------------------------------------------
    
    /// @notice Receive function to handle direct ETH transfers
    /// @dev The use of this.deposit is because deposit() is external
    receive() external payable {
        this.deposit();
    }

    fallback() external payable {
        this.deposit();
    }
}