/**
 *Submitted for verification at snowtrace.io on 2022-08-11
*/

// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract StarkNFT is Ownable, ERC721 {
    using Strings for uint256;

    uint256 _id;
    string _baseEndpoint;
    IERC20 public payToken;
    address public treasury;
    address public NFTmanager;

    // tokenId => NFTtype
    mapping(uint256 => uint256) public tokenURIInfo;
    mapping(uint256 => uint256) public tokenPrice;
    mapping(address => uint256[]) public userInfo;

    constructor (address _token, address _treasury) ERC721("StarkNFT", "StNFT") {
        payToken = IERC20(_token);
        treasury = _treasury;
    }

    modifier onlyManager {
        require(msg.sender == NFTmanager);
        _;
    }

    function setUri(string memory _uri) external onlyOwner {
        _baseEndpoint = _uri;
    }

    function setTokenPrice(uint256 _type, uint256 _price) external onlyOwner {
        tokenPrice[_type] = _price;
    }

    function setNFTManager(address _manager) external onlyOwner {
        NFTmanager = _manager;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint256 tokenType = tokenURIInfo[tokenId];

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenType.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseEndpoint;
    }

    function mint(uint256 _nftType) external returns (uint256) {
        require(tokenPrice[_nftType] > 0, "invalid type");
        uint256 _price = tokenPrice[_nftType];
        _id++;
        uint256 newItemId = _id;
        _safeMint(msg.sender, newItemId);
        tokenURIInfo[newItemId] = _nftType;
        userInfo[msg.sender].push(newItemId);
        payToken.transferFrom(msg.sender, treasury, _price);
        return newItemId;
    }

    function burn(uint256 _tokenId) external onlyManager {
        address _user = ownerOf(_tokenId);
        uint256[] storage _ids = userInfo[_user];
        uint256 _len = _ids.length;
        for (uint256 i = 0; i < _len; i++) {
            if (_ids[i] == _tokenId) {
                _ids[i] = _ids[_len - 1];
                _ids.pop();
                break;
            }
        }
        _burn(_tokenId);
    }

    function getTokenIds(address _user) external view returns(uint256[] memory ids) {
        ids = userInfo[_user];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}