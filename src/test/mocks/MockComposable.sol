// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IComposableToken} from "../../IComposableToken.sol";

contract MockComposable is ERC721 {
    int256 public immutable zIndex;

    constructor(int256 z) ERC721("Mock Composable", "MC") {
        zIndex = z;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IComposableToken).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mint() public virtual {
        _mint(msg.sender, totalSupply);
    }

    function render(uint256 tokenId) public view returns (string memory) {
        return '<g id="mock"></g>';
    }

    function transferToToken(uint256 tokenId, address toToken, uint256 toTokenId) external {
        safeTransferFrom(msg.sender, toToken, tokenId, abi.encode(toTokenId));
    }
}