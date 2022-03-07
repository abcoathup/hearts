// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.12;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Bytes} from "./libraries/Bytes.sol";
import {IComposableSVGToken} from "./IComposableSVGToken.sol";
import {ERC721PayableMintable} from "./ERC721PayableMintable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract ERC721PayableMintableComposableSVG is ERC721PayableMintable, IComposableSVGToken, IERC721Receiver {

    /// ERRORS

    /// @notice Thrown when attempting to add composable token with same Z index
    error SameZIndex();

    /// @notice Thrown when attempting to add a not composable token
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

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint256 price_, 
        uint256 ownerAllocation_,
        uint256 supplyCap_,
        int256 z) 
        ERC721PayableMintable(name_, symbol_, price_, ownerAllocation_, supplyCap_) {
        zIndex = z; 
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IComposableSVGToken).interfaceId || super.supportsInterface(interfaceId);
    }

    function _renderBackground(uint256 tokenId) internal view returns (string memory) {
        string memory background = "";

        if (_composables[tokenId].background.tokenAddress != address(0)) {
            background = IComposableSVGToken(_composables[tokenId].background.tokenAddress).render(_composables[tokenId].background.tokenId);
        }

        return background;
    }

    function _renderForeground(uint256 tokenId) internal view returns (string memory) {
        string memory foreground = "";

        if (_composables[tokenId].foreground.tokenAddress != address(0)) {
            foreground = IComposableSVGToken(_composables[tokenId].foreground.tokenAddress).render(_composables[tokenId].foreground.tokenId);
        }

        return foreground;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 composableTokenId,
        bytes calldata idData) external returns (bytes4) {

        uint256 tokenId = Bytes.toUint256(idData);
   
        IComposableSVGToken composableToken = IComposableSVGToken(msg.sender);
        if (!composableToken.supportsInterface(type(IComposableSVGToken).interfaceId)) revert NotComposableToken();

        if (composableToken.zIndex() < zIndex) {      
             _composables[tokenId].background = Token(msg.sender, composableTokenId);
        } 
        else if (composableToken.zIndex() > zIndex) {      
             _composables[tokenId].foreground = Token(msg.sender, composableTokenId);
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
