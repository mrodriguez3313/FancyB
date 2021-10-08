// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

// ROYALTIES INTERFACE

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

///BASE extends ROYALTIES

// import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

// import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Uses Bitpacking to encode royalties into one bytes32 (saves gas)
    /// @return the bytes32 representation
    function encodeRoyalties(address recipient, uint256 amount)
        public
        pure
        returns (bytes32)
    {
        require(amount <= 10000, '!WRONG_AMOUNT!');
        return bytes32((uint256(uint160(recipient)) << 96) + amount);
    }

    /// @notice Uses Bitpacking to decode royalties from a bytes32
    /// @return recipient and amount
    function decodeRoyalties(bytes32 royalties)
        public
        pure
        returns (address recipient, uint256 amount)
    {
        recipient = address(uint160(uint256(royalties) >> 96));
        amount = uint256(uint96(uint256(royalties)));
    }
}


// ACTUAL CONTRACT

// import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

// import './ERC2981Base.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC165, IERC2981Royalties {
    address _royaltyReceiver;
    uint256 _royaltyPercentX100;
    
    
    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royaltyPercentX100 = value;
        _royaltyReceiver = recipient;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return(_royaltyReceiver, (royaltyAmount*value)/100);
    }
}
