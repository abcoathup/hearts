// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Bytes} from "./libraries/Bytes.sol";
import {IComposableToken} from "./IComposableToken.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract ComposableToken is IComposableToken {

    /// ERRORS

    /// @notice Thrown when attempting to add composible token with same Z index
    error SameZIndex();

    /// @notice Thrown when attempting to add a not composible token
    error NotComposableToken();

    /// EVENTS

    int256 public immutable zIndex;

    struct Token {
        address tokenAddress;
        uint256 tokenId;
    }

    struct Composable {
        Token background;
        Token foreground;
    }

    mapping (uint256 => Composable) private _composables;
    
    bool private ownerMinted = false;

    mapping (uint256 => bytes3) private _colours;
    mapping (uint256 => string) private _names;

    constructor(int256 z) {
        zIndex = z;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IComposableToken).interfaceId;
    }

    function _renderBackground(uint256 tokenId) internal view returns (string memory) {
        string memory background = "";

        if (_composables[tokenId].background.tokenAddress != address(0)) {
            background = IComposableToken(_composables[tokenId].background.tokenAddress).render(_composables[tokenId].background.tokenId);
        }

        return background;
    }

    function _renderForeground(uint256 tokenId) internal view returns (string memory) {
        string memory foreground = "";

        if (_composables[tokenId].foreground.tokenAddress != address(0)) {
            foreground = IComposableToken(_composables[tokenId].foreground.tokenAddress).render(_composables[tokenId].foreground.tokenId);
        }

        return foreground;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 composableTokenId,
        bytes calldata idData) external returns (bytes4) {

        uint256 tokenId = Bytes.toUint256(idData);
   
        IComposableToken composableToken = IComposableToken(msg.sender);
        if (!composableToken.supportsInterface(type(IComposableToken).interfaceId)) revert NotComposableToken();

        if (composableToken.zIndex() < zIndex) {      
             _composables[tokenId].background = Token(msg.sender, tokenId);
        } 
        else if (composableToken.zIndex() > zIndex) {      
             _composables[tokenId].foreground = Token(msg.sender, tokenId);
        }
        else {
            revert SameZIndex();
        }

        return this.onERC721Received.selector;
    }


    function ejectToken(uint256 tokenId, address composableToken, uint256 composableTokenId) external {
        if (_composables[tokenId].background.tokenAddress == composableToken && 
        _composables[tokenId].background.tokenId == composableTokenId) {
           _composables[tokenId].background = Token(address(0), 0);
        } 
        else if (_composables[tokenId].foreground.tokenAddress == composableToken && 
        _composables[tokenId].foreground.tokenId == composableTokenId) {
            _composables[tokenId].foreground = Token(address(0), 0);
        }

        ERC721(composableToken).safeTransferFrom(address(this), msg.sender, composableTokenId);
    }

}
