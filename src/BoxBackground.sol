// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Colours} from "./libraries/Colours.sol";
import {Bytes} from "./libraries/Bytes.sol";
import {IERC4888} from "./IERC4888.sol";
import {ERC721PayableMintable} from "./ERC721PayableMintable.sol";

contract BoxBackground is ERC721PayableMintable, IERC4888 {

    using Colours for bytes3;

    /// ERRORS

    /// EVENTS

    mapping (uint256 => bytes3) private _colours;

    int256 public immutable zIndex;

    constructor() 
        ERC721PayableMintable("Box", "BOX", 0.0001 ether, 23, 230) {
        zIndex = -100;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC4888).interfaceId || super.supportsInterface(interfaceId);
    }

    function _mint() internal override {
        uint256 tokenId = totalSupply;
        
        // from: https://github.com/scaffold-eth/scaffold-eth/blob/48be9829d9c925e4b4cda8735ddc9ff0675d9751/packages/hardhat/contracts/YourCollectible.sol
        bytes32 predictableRandom = keccak256(abi.encodePacked(tokenId, blockhash(block.number), msg.sender, address(this)));
        _colours[tokenId] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );

        super._mint();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();

        string memory tokenName_ = string.concat(name, ' #', Strings.toString(tokenId));
        string memory description = "Box NFT.";

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

    function _generateAttributes(uint256 tokenId) internal view returns (string memory) {

        //TODO get name of accessory and background

        string memory attributes = string.concat('{"trait_type": "colour", "value": "', _colours[tokenId].toColour(), '"}');

        return string.concat('"attributes": [', attributes, ']');
    }

    function _generateBase64Image(uint256 tokenId) internal view returns (string memory) {
        return Base64.encode(bytes(_generateSVG(tokenId)));
    }
    
    function _generateSVG(uint256 tokenId) internal view returns (string memory) {
        string memory svg = string.concat(
            '<svg id="', 'box', Strings.toString(tokenId),
            '" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg">',
            render(tokenId),
            '</svg>'
        );

        return svg;
    }

    function render(uint256 tokenId) public view override returns (string memory) {
        string memory colourValue = string.concat('#',_colours[tokenId].toColour());

        return string.concat(
            '<g id="color">'
            '<path fill="',
            colourValue,
            '" d="M59.5,25c0-6.9036-5.5964-12.5-12.5-12.5c-4.7533,0-8.8861,2.6536-11,6.5598 C33.8861,15.1536,29.7533,12.5,25,12.5c-6.9036,0-12.5,5.5964-12.5,12.5c0,2.9699,1.0403,5.6942,2.7703,7.8387l-0.0043,0.0034 L36,58.5397l20.7339-25.6975l-0.0043-0.0034C58.4597,30.6942,59.5,27.9699,59.5,25z"/>'
            '</g>'
            '<g id="line">'
            '<path fill="none" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M59.5,25 c0-6.9036-5.5964-12.5-12.5-12.5c-4.7533,0-8.8861,2.6536-11,6.5598C33.8861,15.1536,29.7533,12.5,25,12.5 c-6.9036,0-12.5,5.5964-12.5,12.5c0,2.9699,1.0403,5.6942,2.7703,7.8387l-0.0043,0.0034L36,58.5397l20.7339-25.6975l-0.0043-0.0034 C58.4597,30.6942,59.5,27.9699,59.5,25z"/>'
            '</g>'
        );
    }
}
