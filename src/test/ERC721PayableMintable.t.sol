// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "../ERC721PayableMintable.sol";
import "./mocks/MockComposable.sol";

contract ERC721PayableMintableTest is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);
    ERC721PayableMintable token;
    
    uint256 constant PAYMENT = 0.001 ether;
    
    address constant OTHER_ADDRESS = address(1);
    address constant OWNER = address(2);
    address constant PAYMENT_RECIPIENT = address(3);
    address constant TOKEN_HOLDER = address(4);

    string constant NAME = "Name";
    string constant SYMBOL = "SYM";

    uint256 public constant PRICE = 0.001 ether;
    uint256 public constant OWNER_ALLOCATION = 88;  
    uint256 public constant SUPPLY_CAP = 888;
    

    function setUp() public {
        vm.prank(OWNER);
        token = new ERC721PayableMintable(NAME, SYMBOL, PRICE, OWNER_ALLOCATION, SUPPLY_CAP);
    }

    function testMetadata() public {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
    }
    
    /// Mint

    function testMint(uint96 amount) public {
        vm.assume(amount >= PAYMENT);
        token.mint{ value: amount }();

        assertEq(address(token).balance, amount);
        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(address(this)), 1);
        assertEq(token.ownerOf(0), address(this));
    }

    function testMintWithInsufficientPayment(uint96 amount) public {
        vm.assume(amount < PAYMENT);

        vm.expectRevert(ERC721PayableMintable.InsufficientPayment.selector);
        token.mint{ value: amount }();

        assertEq(address(token).balance, 0 ether);
    }

    function testMintWithinCap() public {
        for (uint256 index = 0; index < token.supplyCap(); index++) {
            token.mint{ value: PAYMENT }();
        }

        assertEq(token.totalSupply(), token.supplyCap());
    }

    function testMintOverCap() public {
        for (uint256 index = 0; index < token.supplyCap(); index++) {
            token.mint{ value: PAYMENT }();
        }

        vm.expectRevert(ERC721PayableMintable.SupplyCapReached.selector);
        token.mint{ value: PAYMENT }();

        assertEq(token.totalSupply(), token.supplyCap());
    }

    function testOwnerMint() public {
        vm.prank(OWNER);
        token.ownerMint();

        assertEq(token.totalSupply(), token.ownerAllocation());
        assertEq(token.ownerOf(0), OWNER);
    }

    function testOwnerMintWhenNotOwner() public {
        vm.prank(OTHER_ADDRESS);
        vm.expectRevert("Ownable: caller is not the owner");
        token.ownerMint();
    }

    function testOwnerMintWhenOwnerAlreadyMinted() public {
        vm.prank(OWNER);
        token.ownerMint();

        vm.prank(OWNER);
        vm.expectRevert(ERC721PayableMintable.OwnerAlreadyMinted.selector);
        token.ownerMint();
    }

    function testOwnerMintNearCap() public {
        for (uint256 index = 0; index < token.supplyCap() - 1; index++) {
            token.mint{ value: PAYMENT }();
        }

        vm.prank(OWNER);
        token.ownerMint();

        assertEq(token.totalSupply(), token.supplyCap());
        assertEq(token.ownerOf(token.totalSupply() - 1), OWNER);
    }

    /// Payment

    function testWithdraw(uint96 amount) public {
        vm.assume(amount >= PAYMENT);
        token.mint{ value: amount }();

        vm.prank(OWNER);
        token.withdraw(PAYMENT_RECIPIENT);

        assertEq(address(PAYMENT_RECIPIENT).balance, amount); 
    }

    function testWithdrawWhenNotOwner(uint96 amount) public {
        vm.assume(amount >= PAYMENT);
        token.mint{ value: amount }();

        vm.prank(OTHER_ADDRESS);
        vm.expectRevert("Ownable: caller is not the owner");
        token.withdraw(OTHER_ADDRESS);

        assertEq(address(token).balance, amount); 
        assertEq(address(OTHER_ADDRESS).balance, 0 ether); 
    }

    /// Token URI

    function testTokenURI() public {
        token.mint{ value: PAYMENT }();

        token.tokenURI(0);
    }

    function testTokenURINonexistentToken() public {
        vm.expectRevert(ERC721PayableMintable.NonexistentToken.selector);
        token.tokenURI(0);
    }
}
