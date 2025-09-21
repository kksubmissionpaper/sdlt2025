// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExampleNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    
    struct NFTData {
        string name;
        string description;
        string url;
    }
    
    mapping(uint256 => NFTData) private _nftData;
    
    event NFTMinted(uint256 indexed tokenId, address indexed creator, address indexed owner);
    
    constructor() ERC721("ExampleNFT", "ENFT") Ownable(msg.sender) {}
    
    function mint(
        string memory _name,
        string memory _description,
        string memory _urlString,
        address recipient
    ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter++;
        
        _nftData[tokenId] = NFTData(_name, _description, _urlString);
        _safeMint(recipient, tokenId);
        
        emit NFTMinted(tokenId, msg.sender, recipient);
    }
    
    // Override the tokenURI of the ERC721 
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _nftData[tokenId].url;
    }

}
