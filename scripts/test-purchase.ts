const web3 = new Web3(window.ethereum)

const LooksRareExchange = new web3.eth.Contract(
  LooksRareExchangeABI,
  '0x59728544b08ab483533076417fbbb2fd0b17ce3a'
)

const { encodedParams } = encodeOrderParams(order.params);
const vrs = ethers.utils.splitSignature(order.signature);

const makerAsk: MakerOrderWithVRS = {
  ...order,
  ...vrs,
  params: encodedParams,
};

const takerBid: TakerOrder = {
  isOrderAsk: false,
  taker: accountAddress,
  price: order.price,
  tokenId: order.tokenId,
  minPercentageToAsk: 7500,
  params: encodedParams,
};

const executeOrder = await LooksRareExchange.methods
  .matchAskWithTakerBidUsingETHAndWETH(
    takerBid,
    makerAsk
  ).send(
    from: accountAddress,
    to : "0x59728544b08ab483533076417fbbb2fd0b17ce3a",
    value: makerOrderWithSignature.price
  )