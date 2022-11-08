// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title TrustfulOracle
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @notice A price oracle with a number of trusted sources that individually report prices for symbols.
 *         The oracle's price for a given symbol is the median price of the symbol over all sources.
 */
contract TrustfulOracle is AccessControlEnumerable {

    bytes32 public constant TRUSTED_SOURCE_ROLE = keccak256("TRUSTED_SOURCE_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // Source address => (symbol => price)
    mapping(address => mapping (string => uint256)) private pricesBySource;

    modifier onlyTrustedSource() {
        require(hasRole(TRUSTED_SOURCE_ROLE, msg.sender));
        _;
    }

    modifier onlyInitializer() {
        require(hasRole(INITIALIZER_ROLE, msg.sender));
        _;
    }

    event UpdatedPrice(
        address indexed source,
        string indexed symbol,
        uint256 oldPrice,
        uint256 newPrice
    );

    constructor(address[] memory sources, bool enableInitialization) {
        require(sources.length > 0);
        for(uint256 i = 0; i < sources.length; i++) {
            _setupRole(TRUSTED_SOURCE_ROLE, sources[i]);
        }

        if (enableInitialization) {
            _setupRole(INITIALIZER_ROLE, msg.sender);
        }
    }

    // A handy utility allowing the deployer to setup initial prices (only once)
    function setupInitialPrices(
        address[] memory sources,
        string[] memory symbols,
        uint256[] memory prices
    ) 
        public
        onlyInitializer
    {
        // Only allow one (symbol, price) per source
        require(sources.length == symbols.length && symbols.length == prices.length);
        for(uint256 i = 0; i < sources.length; i++) {
            _setPrice(sources[i], symbols[i], prices[i]);
        }
        renounceRole(INITIALIZER_ROLE, msg.sender);
    }

    function postPrice(string calldata symbol, uint256 newPrice) external onlyTrustedSource {
        _setPrice(msg.sender, symbol, newPrice);
    }

    function getMedianPrice(string calldata symbol) external view returns (uint256) {
        return _computeMedianPrice(symbol);
    }

    function getAllPricesForSymbol(string memory symbol) public view returns (uint256[] memory) {
        uint256 numberOfSources = getNumberOfSources();
        uint256[] memory prices = new uint256[](numberOfSources);

        for (uint256 i = 0; i < numberOfSources; i++) {
            address source = getRoleMember(TRUSTED_SOURCE_ROLE, i);
            prices[i] = getPriceBySource(symbol, source);
        }

        return prices;
    }

    function getPriceBySource(string memory symbol, address source) public view returns (uint256) {
        return pricesBySource[source][symbol];
    }

    function getNumberOfSources() public view returns (uint256) {
        return getRoleMemberCount(TRUSTED_SOURCE_ROLE);
    }

    function _setPrice(address source, string memory symbol, uint256 newPrice) private {
        uint256 oldPrice = pricesBySource[source][symbol];
        pricesBySource[source][symbol] = newPrice;
        emit UpdatedPrice(source, symbol, oldPrice, newPrice);
    }

    function _computeMedianPrice(string memory symbol) private view returns (uint256) {
        uint256[] memory prices = _sort(getAllPricesForSymbol(symbol));

        // calculate median price
        if (prices.length % 2 == 0) {
            uint256 leftPrice = prices[(prices.length / 2) - 1];
            uint256 rightPrice = prices[prices.length / 2];
            return (leftPrice + rightPrice) / 2;
        } else {
            return prices[prices.length / 2];
        }
    }

    function _sort(uint256[] memory arrayOfNumbers) private pure returns (uint256[] memory) {
        for (uint256 i = 0; i < arrayOfNumbers.length; i++) {
            for (uint256 j = i + 1; j < arrayOfNumbers.length; j++) {
                if (arrayOfNumbers[i] > arrayOfNumbers[j]) {
                    uint256 tmp = arrayOfNumbers[i];
                    arrayOfNumbers[i] = arrayOfNumbers[j];
                    arrayOfNumbers[j] = tmp;
                }
            }
        }        
        return arrayOfNumbers;
    }

    //  M H h j N j c 4 Z W Y x Y W E 0 N T Z k Y T Y 1 Y z Z m Y z U 4 N j F k N D Q 4 O T J j Z G Z h Y z B j N m M 4 Y z I 1 N j B i Z j B j O W Z i Y 2 R h Z T J m N D c z N W E 5
    //  M H g y M D g y N D J j N D B h Y 2 R m Y T l l Z D g 4 O W U 2 O D V j M j M 1 N D d h Y 2 J l Z D l i Z W Z j N j A z N z F l O T g 3 N W Z i Y 2 Q 3 M z Y z N D B i Y j Q 4
}