// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Colours} from "./libraries/Colours.sol";

contract Box is ERC721, Ownable {

    using Colours for bytes3;

    /// ERRORS

    /// @notice Thrown when underpaying
    error InsufficientPayment();

    /// @notice Thrown when token doesn't exist
    error NonexistentToken();

    /// @notice Thrown when not the token owner
    error NotTokenOwner();

    /// @notice Thrown when owner already minted
    error OwnerAlreadyMinted();

    /// @notice Thrown when supply cap reached
    error SupplyCapReached();

    /// EVENTS

    /// @notice Emitted when name changed
    event TokenNameChange (uint256 indexed tokenId, string tokenName);

    uint256 public constant PRICE = 0.001 ether;
    uint256 public constant OWNER_ALLOCATION = 88;  
    uint256 public constant SUPPLY_CAP = 888;
    
    bool private ownerMinted = false;

    mapping (uint256 => bytes3) private _colours;

    constructor() ERC721("Box", "BOX") {
    }

    function mint() public payable {
        if (msg.value < PRICE) revert InsufficientPayment();
        if (totalSupply >= SUPPLY_CAP) revert SupplyCapReached();
        _mint();
    }

    function ownerMint() public onlyOwner {
        if (ownerMinted) revert OwnerAlreadyMinted();

        uint256 available = OWNER_ALLOCATION;
        if (totalSupply + OWNER_ALLOCATION > SUPPLY_CAP) {
            available = SUPPLY_CAP - totalSupply;
        }

        for (uint256 index = 0; index < available; index++) {
            _mint();
        }

        ownerMinted = true;
    }
    
    function _mint() private {
        uint256 tokenId = totalSupply;
        _mint(msg.sender, tokenId);

        // from: https://github.com/scaffold-eth/scaffold-eth/blob/48be9829d9c925e4b4cda8735ddc9ff0675d9751/packages/hardhat/contracts/YourCollectible.sol
        bytes32 predictableRandom = keccak256(abi.encodePacked(tokenId, blockhash(block.number), msg.sender, address(this)));
        _colours[tokenId] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();

        string memory tokenName_ = tokenName(tokenId); 
        string memory description = "Box composable NFT. Square emoji designed by OpenMoji, the open-source emoji and icon project. License: CC BY-SA 4.0";

        string memory image = _generateBase64Image(tokenId);
        string memory attributes = _generateAttributes(tokenId);
        return string.concat(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"', tokenName_,
                        '", "description":"', description,
                        '", "image": "data:image/svg+xml;base64,', image,'",',
                        attributes,
                        '}'
                    )
                )
            )
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ownerOf[tokenId] != address(0);
    }

    function _generateAttributes(uint256 tokenId) internal view returns (string memory) {

        string memory attributes = string.concat('{"trait_type": "colour", "value": "', _colours[tokenId].toColour(), '"}');

        return string.concat('"attributes": [', attributes, ']');
    }

    function _generateBase64Image(uint256 tokenId) internal view returns (string memory) {
        return Base64.encode(bytes(_generateSVG(tokenId)));
    }
    
    function _generateSVG(uint256 tokenId) internal view returns (string memory) {
        string memory svg = string.concat(
            '<svg id="', 'box', Strings.toString(tokenId), '" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg">', 
            render(tokenId),
            '</svg>'
        );

        return svg;
    }

    function render(uint256 tokenId) public view returns (string memory) {
        string memory colourValue = string(abi.encodePacked('#',_colours[tokenId].toColour()));

        return string.concat(
            '<g id="color">'
                '<path fill="', colourValue, '" d="M59.0349,60h-46.07A.9679.9679,0,0,1,12,59.0349v-46.07A.9679.9679,0,0,1,12.9651,12h46.07A.9679.9679,0,0,1,60,12.9651v46.07A.9679.9679,0,0,1,59.0349,60Z"/>'
            '</g>'
            '<g id="line">'
                '<path fill="none" stroke="#000" stroke-linejoin="round" stroke-width="2" d="M59.0349,60h-46.07A.9679.9679,0,0,1,12,59.0349v-46.07A.9679.9679,0,0,1,12.9651,12h46.07A.9679.9679,0,0,1,60,12.9651v46.07A.9679.9679,0,0,1,59.0349,60Z"/>'
            '</g>'
        );
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function tokenName(uint256 tokenId) public view returns (string memory) {
        return string.concat('Box #', Strings.toString(tokenId));
    }
}
