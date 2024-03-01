// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {AggregatorV3Interface} from "../vendors/AggregatorV3Interface.sol";

contract MockOracle is AggregatorV3Interface {
  event MockAnswerUpdated(int256 _oldValue, int256 _newValue);

  error ErrNotImplemented();

  int256 public mockAnswer;

  function setMockAnswer(int256 _newValue) external {
    emit MockAnswerUpdated(mockAnswer, _newValue);
    mockAnswer = _newValue;
  }

  // ------

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = 0;
    answer = mockAnswer;
    startedAt = 0;
    updatedAt = 0;
    answeredInRound = 0;
  }

  function decimals() external pure override returns (uint8) {
    return 18;
  }

  function description() external pure override returns (string memory) {
    revert ErrNotImplemented();
  }

  function version() external pure override returns (uint256) {
    revert ErrNotImplemented();
  }

  function getRoundData(
    uint80 /* _roundId */
  )
    external
    pure
    override
    returns (
      uint80 /* roundId */,
      int256 /* answer */,
      uint256 /* startedAt */,
      uint256 /* updatedAt */,
      uint80 /* answeredInRound */
    )
  {
    revert ErrNotImplemented();
  }
}
