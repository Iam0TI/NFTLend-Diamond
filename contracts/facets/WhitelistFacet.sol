// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Events, Errors} from "../libraries/Utils.sol";

contract WhitelistedFacet {
    modifier onlyOwner() {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function whitelistERC20(address _token, bool _status) external onlyOwner {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        require(_token != address(0), Errors.AddressZero());
        l.whitelistedERC20s[_token] = _status;
        emit Events.ERC20Whitelisted(_token, _status);
    }

    function whitelistERC721(address _token, bool _status) external onlyOwner {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        require(_token != address(0), Errors.AddressZero());
        l.whitelistedERC721s[_token] = _status;
        emit Events.ERC721Whitelisted(_token, _status);
    }

    function isERC20Whitelisted(address _token) external view returns (bool) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        return l.whitelistedERC20s[_token];
    }

    function isERC721Whitelisted(address _token) external view returns (bool) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        return l.whitelistedERC721s[_token];
    }
}
