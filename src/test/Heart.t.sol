// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "../Heart.sol";
import "./mocks/MockComposable.sol";

contract HeartTest is DSTest {
    Vm public constant vm = Vm(HEVM_ADDRESS);
    Heart token;
    
    uint256 constant PAYMENT = 0.001 ether;
    
    address constant OTHER_ADDRESS = address(1);
    address constant OWNER = address(2);
    address constant PAYMENT_RECIPIENT = address(3);
    address constant TOKEN_HOLDER = address(4);

    string constant TOKEN_NAME = "Token Name";
    

    function setUp() public {
        vm.prank(OWNER);
        token = new Heart();
    }

    function testMetadata() public {
        assertEq(token.name(), "Heart");
        assertEq(token.symbol(), "HRT");
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

        vm.expectRevert(Heart.InsufficientPayment.selector);
        token.mint{ value: amount }();

        assertEq(address(token).balance, 0 ether);
    }

    function testMintWithinCap() public {
        for (uint256 index = 0; index < token.SUPPLY_CAP(); index++) {
            token.mint{ value: PAYMENT }();
        }

        assertEq(token.totalSupply(), token.SUPPLY_CAP());
    }

    function testMintOverCap() public {
        for (uint256 index = 0; index < token.SUPPLY_CAP(); index++) {
            token.mint{ value: PAYMENT }();
        }

        vm.expectRevert(Heart.SupplyCapReached.selector);
        token.mint{ value: PAYMENT }();

        assertEq(token.totalSupply(), token.SUPPLY_CAP());
    }

    function testOwnerMint() public {
        vm.prank(OWNER);
        token.ownerMint();

        assertEq(token.totalSupply(), token.OWNER_ALLOCATION());
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
        vm.expectRevert(Heart.OwnerAlreadyMinted.selector);
        token.ownerMint();
    }

    function testOwnerMintNearCap() public {
        for (uint256 index = 0; index < token.SUPPLY_CAP() - 1; index++) {
            token.mint{ value: PAYMENT }();
        }

        vm.prank(OWNER);
        token.ownerMint();

        assertEq(token.totalSupply(), token.SUPPLY_CAP());
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
        vm.expectRevert(Heart.NonexistentToken.selector);
        token.tokenURI(0);
    }

    /// Render

    function testRender() public {
        token.mint{ value: PAYMENT }();

        emit log_string(token.render(0));
    }

    /// Token Naming

    function testTokenName() public {
        token.mint{ value: PAYMENT }();

        assertEq(token.tokenName(0), "Heart #0");
    }

    function testChangeTokenName() public {
        token.mint{ value: PAYMENT }();

        token.changeTokenName(0, TOKEN_NAME);
       
        assertEq(token.tokenName(0), TOKEN_NAME);
    }

    function testChangeTokenNameNotTokenOwner() public {
        token.mint{ value: PAYMENT }();

        vm.prank(OTHER_ADDRESS);
        vm.expectRevert(Heart.NotTokenOwner.selector);
        token.changeTokenName(0, TOKEN_NAME);
    }

    function testChangeTokenNameNonexistentToken() public {
        vm.expectRevert(Heart.NonexistentToken.selector);
        token.changeTokenName(0, TOKEN_NAME);
    }

    function testChangeTokenNameInvalidTokenNameEmptyString() public {
        token.mint{ value: PAYMENT }();

        vm.expectRevert(Heart.InvalidTokenName.selector);
        token.changeTokenName(0, "");
    }

    function testChangeTokenNameInvalidTokenNameSpecialCharacters() public {
        token.mint{ value: PAYMENT }();

        vm.expectRevert(Heart.InvalidTokenName.selector);
        token.changeTokenName(0, "-");
    }

    function testChangeTokenNameInvalidTokenNameLeadingSpace() public {
        token.mint{ value: PAYMENT }();

        vm.expectRevert(Heart.InvalidTokenName.selector);
        token.changeTokenName(0, string(abi.encodePacked(" ", TOKEN_NAME)));
    }

    function testChangeTokenNameInvalidTokenNameTrailingSpace() public {
        token.mint{ value: PAYMENT }();

        vm.expectRevert(Heart.InvalidTokenName.selector);
        token.changeTokenName(0, string(abi.encodePacked(TOKEN_NAME, " ")));
    }

    function testChangeTokenNameInvalidTokenNameMultipleSpaces() public {
        token.mint{ value: PAYMENT }();

        vm.expectRevert(Heart.InvalidTokenName.selector);
        token.changeTokenName(0, string(abi.encodePacked(TOKEN_NAME, "  ", TOKEN_NAME)));
    }

    function testChangeTokenNameInvalidTokenNameTooLong() public {
        token.mint{ value: PAYMENT }();

        vm.expectRevert(Heart.InvalidTokenName.selector);
        token.changeTokenName(0, "01234567890123456789012345");
    }

    function testAddBackground(int256 zIndex) public {
        vm.assume(zIndex < 0);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(zIndex);
        composable.mint();

        string memory renderedToken = token.render(0);

        composable.transferToToken(0, address(token), 0);

        assertTrue(keccak256(abi.encodePacked(token.render(0))) != keccak256(abi.encodePacked(renderedToken)));
        assertEq(composable.ownerOf(0), address(token));
    }

    function testAddBackgroundNotOwner() public {
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(-1);
        vm.prank(OTHER_ADDRESS);
        composable.mint();

        vm.prank(OTHER_ADDRESS);
        vm.expectRevert(Heart.NotTokenOwner.selector);
        composable.transferToToken(0, address(token), 0);
    }

    function testEjectBackgroundToEOA() public {
        payable(TOKEN_HOLDER).transfer(1 ether);
        
        vm.prank(TOKEN_HOLDER);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(-1);
        vm.prank(TOKEN_HOLDER);
        composable.mint();

        vm.prank(TOKEN_HOLDER);
        composable.transferToToken(0, address(token), 0);

        vm.prank(TOKEN_HOLDER);
        token.ejectToken(0, address(composable), 0);
    }

    function testAddForeground(int256 zIndex) public {
        vm.assume(zIndex > 0);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(zIndex);
        composable.mint();

        string memory renderedToken = token.render(0);

        composable.transferToToken(0, address(token), 0);

        assertTrue(keccak256(abi.encodePacked(token.render(0))) != keccak256(abi.encodePacked(renderedToken)));
        assertEq(composable.ownerOf(0), address(token));
    }

    function testAddForegroundNotOwner() public {
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(1);
        vm.prank(OTHER_ADDRESS);
        composable.mint();

        vm.prank(OTHER_ADDRESS);
        vm.expectRevert(Heart.NotTokenOwner.selector);
        composable.transferToToken(0, address(token), 0);
    }

    function testEjectForegroundToEOA() public {
        payable(TOKEN_HOLDER).transfer(1 ether);
        
        vm.prank(TOKEN_HOLDER);
        token.mint{ value: PAYMENT }();

        MockComposable composable = new MockComposable(1);
        vm.prank(TOKEN_HOLDER);
        composable.mint();

        vm.prank(TOKEN_HOLDER);
        composable.transferToToken(0, address(token), 0);

        vm.prank(TOKEN_HOLDER);
        token.ejectToken(0, address(composable), 0);
    }

    function testAddForegroundAndBackground() public {
        token.mint{ value: PAYMENT }();

        string memory renderedToken = token.render(0);

        MockComposable foreground = new MockComposable(1);
        foreground.mint();
        foreground.transferToToken(0, address(token), 0);

        MockComposable background = new MockComposable(1);
        background.mint();
        background.transferToToken(0, address(token), 0);

        assertTrue(keccak256(abi.encodePacked(token.render(0))) != keccak256(abi.encodePacked(renderedToken)));
        assertEq(foreground.ownerOf(0), address(token));
        assertEq(background.ownerOf(0), address(token));
    }
}
