// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Colours} from "./libraries/Colours.sol";
import {Bytes} from "./libraries/Bytes.sol";
import {IERC4883} from "./IERC4883.sol";
import {ERC721PayableMintable} from "./ERC721PayableMintable.sol";

contract GlassesForeground is ERC721PayableMintable, IERC4883 {
    using Colours for bytes3;

    /// ERRORS

    /// EVENTS

    mapping(uint256 => bytes3) private _colours;

    int256 public immutable zIndex;

    constructor()
        ERC721PayableMintable("Glasses", "GLS", 0.0001 ether, 13, 130)
    {
        zIndex = 100;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC4883).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _mint() internal override {
        uint256 tokenId = totalSupply;

        // from: https://github.com/scaffold-eth/scaffold-eth/blob/48be9829d9c925e4b4cda8735ddc9ff0675d9751/packages/hardhat/contracts/YourCollectible.sol
        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                tokenId,
                blockhash(block.number),
                msg.sender,
                address(this)
            )
        );
        _colours[tokenId] =
            bytes2(predictableRandom[0]) |
            (bytes2(predictableRandom[1]) >> 8) |
            (bytes3(predictableRandom[2]) >> 16);

        super._mint();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonexistentToken();

        string memory tokenName_ = string.concat(
            name,
            " #",
            Strings.toString(tokenId)
        );
        string memory description = "Glasses NFT.";

        string memory image = _generateBase64Image(tokenId);
        string memory attributes = _generateAttributes(tokenId);
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            tokenName_,
                            '", "description":"',
                            description,
                            '", "image": "data:image/svg+xml;base64,',
                            image,
                            '",',
                            attributes,
                            "}"
                        )
                    )
                )
            );
    }

    function _generateAttributes(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        //TODO get name of accessory and background

        string memory attributes = string.concat(
            '{"trait_type": "colour", "value": "',
            _colours[tokenId].toColour(),
            '"}'
        );

        return string.concat('"attributes": [', attributes, "]");
    }

    function _generateBase64Image(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return Base64.encode(bytes(_generateSVG(tokenId)));
    }

    function _generateSVG(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory svg = string.concat(
            '<svg id="',
            "glasses",
            Strings.toString(tokenId),
            '" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg">',
            render(tokenId),
            "</svg>"
        );

        return svg;
    }

    function render(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory colourValue = string.concat(
            "#",
            _colours[tokenId].toColour()
        );

        return
            string.concat(
                '<g id="color">'
                '<path fill="',
                colourValue,
                '" stroke="',
                colourValue,
                '" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M37.5891,34.151 c1.0309-0.1557,2.3936-0.355,3.1719,3.5553c0.5088,2.5561,2.4518,2.3815,3.5921,4.0059c2.3054,3.2843,7.0505,5.5111,11.3652,5.5111 c6.9036,0,12.5-5.5964,12.5-12.5l0.105-4.9141l1.895,0.0501v-4.1273c0,0-18.9318-16.1788-29.4804,5.3212h-2.9812h-0.4615H34.314 c-10.5486-21.5-29.4804-5.3212-29.4804-5.3212v4.1273l1.895-0.0501l0.105,4.9141c0,6.9036,5.5964,12.5,12.5,12.5 c4.3147,0,9.1189-2.1861,11.3652-5.5111"/>'
                '<path fill="',
                colourValue,
                '" stroke="',
                colourValue,
                '" stroke-miterlimit="10" stroke-width="2" d="M37.5891,34.151 c1.0309-0.1557,2.3936-0.355,3.1719,3.5553c0.5088,2.5561,2.4518,2.3815,3.5921,4.0059c2.3054,3.2843,7.0505,5.5111,11.3652,5.5111"/>'
                '<path fill="',
                colourValue,
                '" stroke="',
                colourValue,
                '" stroke-miterlimit="10" stroke-width="2" d="M37.7915,33.8289 c-6.7199-0.9921-2.7978,3.4384-3.0884,3.9105c-1.3989,2.2732-2.5354,2.0263-3.6757,3.6507 c-2.3054,3.2843-7.0505,5.5111-11.3652,5.5111"/>'
                '<circle cx="19.7664" cy="33.5577" r="9.5798" fill="#000000" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.8457"/>'
                '<circle cx="55.2856" cy="33.5577" r="9.5798" fill="#000000" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.8457"/>'
                '<path fill="',
                colourValue,
                '" stroke="',
                colourValue,
                '" stroke-miterlimit="10" stroke-width="2" d="M34.0453,39.8045"/>'
                "</g>"
                '<g id="line">'
                '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M30.6989,41.7122c-2.2463,3.325-7.0505,5.5111-11.3652,5.5111c-6.9036,0-12.5-5.5964-12.5-12.5l-0.105-4.9141l-1.895,0.0501 v-4.1273c0,0,18.9318-16.1788,29.4804,5.3212h2.9812h0.4615h2.9812c10.5486-21.5,29.4804-5.3212,29.4804-5.3212v4.1273 l-1.895-0.0501l-0.105,4.9141c0,6.9036-5.5964,12.5-12.5,12.5c-4.3147,0-9.1189-2.1861-11.3652-5.5111"/>'
                '<path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M34.761,37.7063c0-1.6569,1.3431-3,3-3c1.6569,0,3,1.3431,3,3"/>'
                '<circle cx="19.7664" cy="33.5577" r="9.5798" fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.8457"/>'
                '<circle cx="55.2856" cy="33.5577" r="9.5798" fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="1.8457"/>'
                "</g>"
            );
    }
}
