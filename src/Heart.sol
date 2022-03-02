// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Colours} from "./libraries/Colours.sol";
import {Bytes} from "./libraries/Bytes.sol";
import {IComposableToken} from "./IComposableToken.sol";
import {ComposableToken} from "./ComposableToken.sol";
import {NamedToken} from "./NamedToken.sol";

contract Heart is ERC721, ComposableToken, NamedToken, Ownable {

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


    uint256 public constant PRICE = 0.001 ether;
    uint256 public constant OWNER_ALLOCATION = 88;  
    uint256 public constant SUPPLY_CAP = 888;
 
    bool private ownerMinted = false;

    mapping (uint256 => bytes3) private _colours;
    mapping (uint256 => string) private _names;

    constructor() ERC721("Heart", "HRT") ComposableToken(0) NamedToken("Heart") {
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ComposableToken, ERC721) returns (bool) {
        return interfaceId == type(IComposableToken).interfaceId || super.supportsInterface(interfaceId);
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
        string memory description = "Heart NFT. Heart emoji designed by OpenMoji, the open-source emoji and icon project. License: CC BY-SA 4.0";

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

        //TODO get name of accessory and background

        string memory attributes = string.concat('{"trait_type": "colour", "value": "', _colours[tokenId].toColour(), '"}');

        return string.concat('"attributes": [', attributes, ']');
    }

    function _generateBase64Image(uint256 tokenId) internal view returns (string memory) {
        return Base64.encode(bytes(_generateSVG(tokenId)));
    }
    
    function _generateSVG(uint256 tokenId) internal view returns (string memory) {
        string memory svg = string.concat(
            '<svg id="', 'heart', Strings.toString(tokenId),
            '" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg">',
            render(tokenId),
            '</svg>'
        );

        return svg;
    }

    function render(uint256 tokenId) public view override returns (string memory) {
        string memory colourValue = string.concat('#',_colours[tokenId].toColour());

        return string.concat(
            _renderBackground(tokenId),
            '<g id="color">'
            '<path fill="',
            colourValue,
            '" d="M59.5,25c0-6.9036-5.5964-12.5-12.5-12.5c-4.7533,0-8.8861,2.6536-11,6.5598 C33.8861,15.1536,29.7533,12.5,25,12.5c-6.9036,0-12.5,5.5964-12.5,12.5c0,2.9699,1.0403,5.6942,2.7703,7.8387l-0.0043,0.0034 L36,58.5397l20.7339-25.6975l-0.0043-0.0034C58.4597,30.6942,59.5,27.9699,59.5,25z"/>'
            '</g>'
            '<g id="line">'
            '<path fill="none" stroke="#000000" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M59.5,25 c0-6.9036-5.5964-12.5-12.5-12.5c-4.7533,0-8.8861,2.6536-11,6.5598C33.8861,15.1536,29.7533,12.5,25,12.5 c-6.9036,0-12.5,5.5964-12.5,12.5c0,2.9699,1.0403,5.6942,2.7703,7.8387l-0.0043,0.0034L36,58.5397l20.7339-25.6975l-0.0043-0.0034 C58.4597,30.6942,59.5,27.9699,59.5,25z"/>'
            '</g>',
            _renderForeground(tokenId)
        );
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    // Based on The HashMarks
    // https://etherscan.io/address/0xc2c747e0f7004f9e8817db2ca4997657a7746928#code#F7#L311
    function changeTokenName(uint256 tokenId, string memory newTokenName) external {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (_msgSender() != ownerOf[tokenId]) revert NotTokenOwner();
        
        _changeTokenName(tokenId, newTokenName);
    }
}
