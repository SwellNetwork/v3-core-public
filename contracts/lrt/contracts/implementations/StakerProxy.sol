// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {ISignatureVerification} from "../interfaces/ISignatureVerification.sol";
import {IStakerProxy} from "../interfaces/IStakerProxy.sol";
import {IEigenPodManager} from "../vendors/contracts/interfaces/IEigenPodManager.sol";
import {IEigenPod} from "../vendors/contracts/interfaces/IEigenPod.sol";
import {IDelegationManager} from "../vendors/contracts/interfaces/IDelegationManager.sol";
import {IStrategy} from "../vendors/contracts/interfaces/IStrategy.sol";
import {IStrategyManager} from "../vendors/contracts/interfaces/IStrategyManager.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {DepositDataRoot} from "../libraries/DepositDataRoot.sol";

import {SwellLib} from "../libraries/SwellLib.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {DepositManager} from "../implementations/DepositManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IEigenLayerManager} from "../interfaces/IEigenLayerManager.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {BeaconChainProofs} from "../vendors/contracts/libraries/BeaconChainProofs.sol";

/**
 * @title StakerProxy
 * @dev This contract is a proxy contract used to interact with EigenLayer. It manages an EigenPod and stake in EigenLayer.
 * @dev It provides an interface around pod/delegation methods: to stake/withdraw ETH, to deposit/withdraw ERC20 tokens, and manage delegation to operators.
 * @dev This contract is an ERC-1271 signature verifier, implementing a custom scheme which requires delegation signatures be signed by the admin signer.
 */
contract StakerProxy is IStakerProxy, ISignatureVerification, Initializable {
    using SafeERC20 for IERC20;

    IAccessControlManager public AccessControlManager;
    IDelegationManager public DelegationManager;
    IEigenPodManager public EigenPodManager;

    address public eigenPod;
    address public depositManager;
    address public eigenLayerManager;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier checkRole(bytes32 role) {
        AccessControlManager.checkRole(role, msg.sender);
        _;
    }

    /**
    * @dev Modifier to check for empty addresses
    * @param _address The address to check
    */
    modifier checkZeroAddress(address _address) {
        SwellLib._checkZeroAddress(_address);

        _;
    }

    modifier checkEigenLayerManager(address _address) {
        if(msg.sender != eigenLayerManager) {
            revert NotEigenLayerManager();
        }
        _;
    }

    function initialize(
        IAccessControlManager _accessControlManager,
        address _delegationManager,
        address _eigenPodManager,
        address _depositManager,
        address _eigenLayerManager
    )  public initializer
        checkZeroAddress(address(_accessControlManager))
        checkZeroAddress(_delegationManager)
        checkZeroAddress(_depositManager)
        checkZeroAddress(_eigenLayerManager) {
        AccessControlManager = _accessControlManager;
        DelegationManager = IDelegationManager(_delegationManager);
        depositManager = _depositManager;
        eigenLayerManager = _eigenLayerManager;

        EigenPodManager = IEigenPodManager(_eigenPodManager);
        eigenPod = EigenPodManager.createPod();
    }

    function stakeOnEigenLayer(
        bytes calldata _pubKeys,
        bytes calldata _signatures
    ) external payable checkEigenLayerManager(msg.sender){
        bytes32 depositDataRoot = DepositDataRoot.formatDepositDataRoot(
            _pubKeys,
            generateWithdrawalCredentialsForEigenPod(),
            _signatures,
            msg.value
        );

        EigenPodManager.stake{value: msg.value}(_pubKeys, _signatures, depositDataRoot);
    }

    function depositIntoStrategy(
        IStrategy currentStrategy, 
        IERC20 token, 
        uint256 _amount
    ) external checkEigenLayerManager(msg.sender){
        address strategyManagerAddress = IEigenLayerManager(eigenLayerManager).strategyManagerAddress();
        token.safeIncreaseAllowance(strategyManagerAddress, _amount);
        IStrategyManager(strategyManagerAddress).depositIntoStrategy(currentStrategy, token, _amount);
    }

    function undelegateFromOperator() public checkEigenLayerManager(msg.sender) returns (bytes32[] memory withdrawalRoots) {
        withdrawalRoots = DelegationManager.undelegate(address(this));
    }

    function withdrawNonStakedBeaconChainEth(
        address _recipient, 
        uint256 _amount
    ) external checkRole(SwellLib.EIGENLAYER_WITHDRAWALS){
        IEigenPod(eigenPod).withdrawNonBeaconChainETHBalanceWei(_recipient, _amount);
    }

    function withdrawERC20FromPod(
        IERC20[] memory _tokens, 
        uint256[] memory _amounts, 
        address _recipient
    ) external checkEigenLayerManager(msg.sender) {
        if(_tokens.length != _amounts.length) {
            revert ArrayLengthMismatch();
        }

        IEigenPod(eigenPod).recoverTokens(_tokens, _amounts, _recipient);
    }

    function verifyPodWithdrawalCredentials(
        uint64 _oracleTimestamp,
        BeaconChainProofs.StateRootProof calldata _stateRootProof,
        uint40[] calldata _validatorIndices,
        bytes[] calldata _validatorFieldsProofs,
        bytes32[][] calldata _validatorFields
    ) external checkEigenLayerManager(msg.sender) {
        IEigenPod(eigenPod).verifyWithdrawalCredentials(
            _oracleTimestamp,
            _stateRootProof,
            _validatorIndices,
            _validatorFieldsProofs,
            _validatorFields
        );
    }

    /// @dev This function is used to withdraw beacon chain rewards as a partial withdrawal
    /// @dev This function is used in conjunction with queueWithdrawals to process a full withdrawal
    function verifyAndProcessWithdrawals(
        uint64 _oracleTimestamp,
        BeaconChainProofs.StateRootProof calldata _stateRootProof,
        BeaconChainProofs.WithdrawalProof[] calldata _withdrawalProofs,
        bytes[] calldata _validatorFieldsProofs,
        bytes32[][] calldata _validatorFields,
        bytes32[][] calldata _withdrawalFields
    ) external checkEigenLayerManager(msg.sender) {
        IEigenPod(eigenPod).verifyAndProcessWithdrawals(
            _oracleTimestamp, 
            _stateRootProof, 
            _withdrawalProofs,
            _validatorFieldsProofs, 
            _validatorFields, 
            _withdrawalFields
        );
    }

    function queueWithdrawals(
        IDelegationManager.QueuedWithdrawalParams[] calldata _queuedWithdrawalParams
    ) external checkEigenLayerManager(msg.sender) returns (bytes32[] memory) {
        bytes32[] memory withdrawalRoots = DelegationManager.queueWithdrawals(_queuedWithdrawalParams);
        return withdrawalRoots;
    }

    function completeQueuedWithdrawal(
        IDelegationManager.Withdrawal calldata _withdrawal,
        IERC20[] calldata _tokens,
        uint256 _middlewareTimesIndex,
        bool _receiveAsTokens
    ) external checkEigenLayerManager(msg.sender) {
        DelegationManager.completeQueuedWithdrawal(
            _withdrawal, 
            _tokens, 
            _middlewareTimesIndex, 
            _receiveAsTokens
        );
    }

    function sendFundsToDepositManager() external checkRole(SwellLib.BOT) {
        if (AccessControlManager.botMethodsPaused()) {
            revert SwellLib.BotMethodsPaused();
        }
        (bool success, ) = depositManager.call{ value: address(this).balance }("");
        if (!success){
            revert ETHTransferFailed();
        }
    }

    function sendTokenBalanceToDepositManager(
        IERC20 _token
    ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
        uint256 contractBalance = _token.balanceOf(address(this));
        if (contractBalance == 0) {
            revert SwellLib.NoTokensToWithdraw();
        }

        _token.safeTransfer(address(depositManager), contractBalance);
    }

    function implementation() external view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1);
        address beaconImplementation;
        assembly {
            beaconImplementation := sload(slot)
        }

        IBeacon beacon = IBeacon(beaconImplementation);
        return beacon.implementation();
    }

    /**
     * @notice Implementation of EIP-1271 signature validation method.
     * @param _dataHash Hash of the data signed on the behalf of address(msg.sender)
     * @param _signature Signature byte array associated with _dataHash
     * @return Updated EIP1271 magic value if signature is valid, otherwise 0x0
     */
    function isValidSignature(bytes32 _dataHash, bytes calldata _signature) public view override returns (bytes4) {
        address recoveredAddr = ECDSA.recover(ECDSA.toEthSignedMessageHash(_dataHash), _signature);
        return recoveredAddr == IEigenLayerManager(eigenLayerManager).adminSigner() ? EIP1271_MAGIC_VALUE : bytes4(0);
    }

    function generateWithdrawalCredentialsForEigenPod() public view returns (bytes memory){
        return abi.encodePacked(bytes1(0x01), bytes11(0x0), address(eigenPod));
    }

    function getAmountOfNonBeaconChainEth() public view returns (uint256) {
        return IEigenPod(eigenPod).nonBeaconChainETHBalanceWei();
    }

    receive() external payable {
    }
}