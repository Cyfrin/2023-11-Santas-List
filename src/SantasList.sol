// SPDX-License-Identifier: MIT

// Art by Shanaka Dias
// https://www.asciiart.eu/holiday-and-events/christmas/santa-claus
//
//     |,\/,| |[_' |[_]) |[_]) \\//
//     ||\/|| |[_, ||'\, ||'\,  ||
//
//             ___ __ __ ____  __  __  ____  _  _    __    __
//            // ' |[_]| |[_]) || ((_' '||' |,\/,|  //\\  ((_'
//            \\_, |[']| ||'\, || ,_))  ||  ||\/|| //``\\ ,_))
//
//                                          ,;7,
//                                        _ ||:|,
//                      _,---,_           )\'  '|
//                    .'_.-.,_ '.         ',')  j
//                   /,'   ___}  \        _/   /
//       .,         ,1  .''  =\ _.''.   ,`';_ |
//     .'  \        (.'T ~, (' ) ',.'  /     ';',
//     \   .\(\O/)_. \ (    _Z-'`>--, .'',      ;
//      \  |   I  _|._>;--'`,-j-'    ;    ',  .'
//     __\_|   _.'.-7 ) `'-' "       (      ;'
//   .'.'_.'|.' .'   \ ',_           .'\   /
//   | |  |.'  /      \   \          l  \ /
//   | _.-'   /        '. ('._   _ ,.'   \i
// ,--' ---' / k  _.-,.-|__L, '-' ' ()    ;
//  '._     (   ';   (    _-}             |
//   / '     \   ;    ',.__;         ()   /
//  /         |   ;    ; ___._._____.: :-j
// |           \,__',-' ____: :_____.: :-\
// |               F :   .  ' '        ,  L
// ',             J  |   ;             j  |
//   \            |  |    L            |  J
//    ;         .-F  |    ;           J    L
//     \___,---' J'--:    j,---,___   |_   |
//               |   |'--' L       '--| '-'|
//                '.,L     |----.__   j.__.'
//                 | '----'   |,   '-'  }
//                 j         / ('-----';
//                { "---'--;'  }       |
//                |        |   '.----,.'
//                ',.__.__.'    |=, _/
//                 |     /      |    '.
//                 |'= -x       L___   '--,
//                 L   __\          '-----'
//                  '.____)
pragma solidity 0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {TokenUri} from "./TokenUri.sol";
import {SantaToken} from "./SantaToken.sol";

/* 
 * @title SantasList
 * @author South Pole Elves 0x815f577f1c1bce213c012f166744937c889daf17
 * 
 * @notice Santas's naughty or nice list, all on chain!
 */
contract SantasList is ERC721, TokenUri {
    error SantasList__NotSanta();
    error SantasList__SecondCheckDoesntMatchFirst();
    error SantasList__NotChristmasYet();
    error SantasList__AlreadyCollected();
    error SantasList__NotNice();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    enum Status {
        NICE,
        EXTRA_NICE,
        NAUGHTY,
        NOT_CHECKED_TWICE
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(address person => Status naughtyOrNice) private s_theListCheckedOnce;
    mapping(address person => Status naughtyOrNice) private s_theListCheckedTwice;
    address private immutable i_santa;
    uint256 private s_tokenCounter;
    SantaToken private immutable i_santaToken;

    // This variable is ok even if it's off by 24 hours.
    uint256 public constant CHRISTMAS_2023_BLOCK_TIME = 1_703_480_381;
    // The cost of santa tokens for naughty people to buy presents
    uint256 public constant PURCHASED_PRESENT_COST = 2e18;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CheckedOnce(address person, Status status);
    event CheckedTwice(address person, Status status);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlySanta() {
        if (msg.sender != i_santa) {
            revert SantasList__NotSanta();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() ERC721("Merry Christmas 2023", "SANTA") {
        i_santa = msg.sender;
        i_santaToken = new SantaToken(address(this));
    }

    /* 
     * @notice Do a first pass on someone if they are naughty or nice. 
     * Only callable by santa
     * 
     * @param person The person to check
     * @param status The status of the person
     */
    function checkList(address person, Status status) external {
        s_theListCheckedOnce[person] = status;
        emit CheckedOnce(person, status);
    }

    /* 
     * @notice Do a second pass on someone if they are naughty or nice. 
     * Only callable by santa. Only if they pass this are they eligible for a present.
     * 
     * @param person The person to check
     * @param status The status of the person
     */
    function checkTwice(address person, Status status) external onlySanta {
        if (s_theListCheckedOnce[person] != status) {
            revert SantasList__SecondCheckDoesntMatchFirst();
        }
        s_theListCheckedTwice[person] = status;
        emit CheckedTwice(person, status);
    }

    /*
     * @notice Collect your present if you are nice or extra nice. You get extra presents if you are extra nice.
     *  - Nice: Collect an NFT
     *  - Extra Nice: Collect an NFT and a SantaToken
     * This should not be callable until Christmas 2023 (give or take 24 hours), and addresses should not be able to collect more than once.
     */
    function collectPresent() external {
        if (block.timestamp < CHRISTMAS_2023_BLOCK_TIME) {
            revert SantasList__NotChristmasYet();
        }
        if (balanceOf(msg.sender) > 0) {
            revert SantasList__AlreadyCollected();
        }
        if (s_theListCheckedOnce[msg.sender] == Status.NICE && s_theListCheckedTwice[msg.sender] == Status.NICE) {
            _mintAndIncrement();
            return;
        } else if (
            s_theListCheckedOnce[msg.sender] == Status.EXTRA_NICE
                && s_theListCheckedTwice[msg.sender] == Status.EXTRA_NICE
        ) {
            _mintAndIncrement();
            i_santaToken.mint(msg.sender);
            return;
        }
        revert SantasList__NotNice();
    }

    /* 
     * @notice Buy a present for someone else. This should only be callable by anyone with SantaTokens.
     * @dev You'll first need to approve the SantasList contract to spend your SantaTokens.
     */
    function buyPresent(address presentReceiver) external {
        i_santaToken.burn(presentReceiver);
        _mintAndIncrement();
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL AND PRIVATE
    //////////////////////////////////////////////////////////////*/
    function _mintAndIncrement() private {
        _safeMint(msg.sender, s_tokenCounter++);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function tokenURI(uint256 /* tokenId */ ) public pure override returns (string memory) {
        return TOKEN_URI;
    }

    function getSantaToken() external view returns (address) {
        return address(i_santaToken);
    }

    function getNaughtyOrNiceOnce(address person) external view returns (Status) {
        return s_theListCheckedOnce[person];
    }

    function getNaughtyOrNiceTwice(address person) external view returns (Status) {
        return s_theListCheckedTwice[person];
    }

    function getSanta() external view returns (address) {
        return i_santa;
    }
}

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
