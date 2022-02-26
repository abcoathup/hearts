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

contract Heart is ERC721, IComposableToken, Ownable {

    using Colours for bytes3;

    /// ERRORS

    /// @notice Thrown when underpaying
    error InsufficientPayment();

    /// @notice Thrown when token doesn't exist
    error NonexistentToken();

    /// @notice Thrown when attempting to set an invalid token name
    error InvalidTokenName();

    /// @notice Thrown when not the token owner
    error NotTokenOwner();

    /// @notice Thrown when owner already minted
    error OwnerAlreadyMinted();

    /// @notice Thrown when supply cap reached
    error SupplyCapReached();

    /// @notice Thrown when attempting to add composible token with same Z index
    error SameZIndex();

    /// @notice Thrown when attempting to add a not composible token
    error NotComposableToken();

    /// EVENTS

    /// @notice Emitted when name changed
    event TokenNameChange (uint256 indexed tokenId, string tokenName);

    int256 public immutable zIndex;

    uint256 public constant PRICE = 0.001 ether;
    uint256 public constant OWNER_ALLOCATION = 88;  
    uint256 public constant SUPPLY_CAP = 888;

    struct ComposableToken {
        address tokenAddress;
        uint256 tokenId;
    }

    struct Composable {
        ComposableToken background;
        ComposableToken foreground;
    }

    mapping (uint256 => Composable) private _composables;
    
    bool private ownerMinted = false;

    mapping (uint256 => bytes3) private _colours;
    mapping (uint256 => string) private _names;

    constructor() ERC721("Heart", "HRT") {
        zIndex = 0;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(IERC165, ERC721) returns (bool) {
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

    function render(uint256 tokenId) public view returns (string memory) {
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

    function _renderBackground(uint256 tokenId) private view returns (string memory) {
        string memory background = "";

        if (_composables[tokenId].background.tokenAddress != address(0)) {
            background = IComposableToken(_composables[tokenId].background.tokenAddress).render(_composables[tokenId].background.tokenId);
        }

        return background;
    }

    function _renderForeground(uint256 tokenId) private view returns (string memory) {
        string memory foreground = "";

        if (_composables[tokenId].foreground.tokenAddress != address(0)) {
            foreground = IComposableToken(_composables[tokenId].foreground.tokenAddress).render(_composables[tokenId].foreground.tokenId);
        }

        return foreground;
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function tokenName(uint256 tokenId) public view returns (string memory) {
        string memory tokenName_ = _names[tokenId];

        bytes memory b = bytes(tokenName_);
        if(b.length < 1) {
            tokenName_ = string(abi.encodePacked('Heart #', Strings.toString(tokenId)));
        }

        return tokenName_;
    }

    // Based on The HashMarks
    // https://etherscan.io/address/0xc2c747e0f7004f9e8817db2ca4997657a7746928#code#F7#L311
    function changeTokenName(uint256 tokenId, string memory newTokenName) public {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (_msgSender() != ownerOf[tokenId]) revert NotTokenOwner();
        if (!validateTokenName(newTokenName)) revert InvalidTokenName();
    
        _names[tokenId] = newTokenName;

        emit TokenNameChange(tokenId, newTokenName);
    }

    // From The HashMarks
    // https://etherscan.io/address/0xc2c747e0f7004f9e8817db2ca4997657a7746928#code#F7#L612
    function validateTokenName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 composableTokenId,
        bytes calldata idData) external returns (bytes4) {

        uint256 tokenId = Bytes.toUint256(idData);

        if (ownerOf[tokenId] != from) revert NotTokenOwner();
   
        IComposableToken composableToken = IComposableToken(msg.sender);
        if (!composableToken.supportsInterface(type(IComposableToken).interfaceId)) revert NotComposableToken();

        if (composableToken.zIndex() < zIndex) {      
             _composables[tokenId].background = ComposableToken(msg.sender, tokenId);
        } 
        else if (composableToken.zIndex() > zIndex) {      
             _composables[tokenId].foreground = ComposableToken(msg.sender, tokenId);
        }
        else {
            revert SameZIndex();
        }

        return this.onERC721Received.selector;
    }


    function ejectToken(uint256 tokenId, address composableToken, uint256 composableTokenId) external {
        if (_composables[tokenId].background.tokenAddress == composableToken && 
        _composables[tokenId].background.tokenId == composableTokenId) {
           _composables[tokenId].background = ComposableToken(address(0), 0);
        } 
        else if (_composables[tokenId].foreground.tokenAddress == composableToken && 
        _composables[tokenId].foreground.tokenId == composableTokenId) {
            _composables[tokenId].foreground = ComposableToken(address(0), 0);
        }

        // TODO add support for ERC1155
        ERC721(composableToken).safeTransferFrom(address(this), msg.sender, composableTokenId);
    }

}
