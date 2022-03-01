// SPDX-License-Identifier: GPL-3.0
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

contract MConst {
    uint public constant BONE                   = 10 ** 18;

    uint public constant NONE_LEVEL             = 0;
    uint public constant APPRENTICE_LEVEL       = 5;
    uint public constant ELITE_LEVEL            = 4;
    uint public constant EPIC_LEVEL             = 3;
    uint public constant LEGEND_LEVEL           = 2;
    uint public constant GENESIS_LEVEL          = 1;

    uint public constant APPRENTICE_AMOUNT      = BONE * 100;
    uint public constant ELITE_AMOUNT           = BONE * 1000;
    uint public constant EPIC_AMOUNT            = BONE * 5000;
    uint public constant LEGEND_AMOUNT          = BONE * 10000;
    uint public constant GENESIS_AMOUNT         = BONE * 100000;

    uint public constant APPRENTICE_TIME        = 5 days;
    uint public constant ELITE_TIME             = 8 days;
    uint public constant EPIC_TIME              = 15 days;
    uint public constant LEGEND_TIME            = 24 days;
    uint public constant GENESIS_TIME           = 30 days;
}
