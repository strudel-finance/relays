/* global artifacts */

const args = require('./args');
const Relay = artifacts.require('Relay');

module.exports = async (deployer) => {
  const { genesis, height, anchorHeigth, anchorParentTime, anchorNBits } = args;
  deployer.deploy(Relay, genesis, height, anchorHeigth, anchorParentTime, anchorNBits);
};
