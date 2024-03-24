// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AuctionTokenFacet  is IERC20{
    LibAppStorage.Layout internal at;

    function onlyOwner() private view {
        require(
            msg.sender == at.owner,
            "Only Onwer can perform this transaction"
        );
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view  returns (string memory) {
        return at.name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view  returns (string memory) {
        return at.symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view  returns (uint8) {
        return at.decimal;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view  returns (uint256) {
        return at.totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view  returns (uint256) {
        return at.balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(
        address _to,
        uint256 _value
    ) public  returns (bool) {
        require(
            msg.sender != address(0),
            "Address zero cannot make a transfer"
        );
        require(
            at.balances[msg.sender] > _value,
            "You don't have enough balance"
        );
        at.balances[msg.sender] = at.balances[msg.sender] - _value;
        at.balances[_to] = at.balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view  returns (uint256) {
        return at.allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(
            at.balances[msg.sender] >= _value,
            "You don't have enough token to allocate"
        );
        at.allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the ERC. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_from != address(0), "Address zero cannot make a transfer");
        require(_from != _to, "You can't transfer to yourself");
        require(
            at.allowances[_from][_to] >= _value,
            "You allocation is not enough, Message the owner for more allocations"
        );
        at.balances[_from] = at.balances[_from] - _value;
        at.allowances[_from][_to] = at.allowances[_from][_to] - _value;
        at.balances[_to] = at.balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not , {_update} should be overridden instead.
     */
    function mint(address _to, uint256 _value) external {
        onlyOwner();

        require(_to != address(0), "Invalid address");

        require(at.totalSupply + _value >= at.totalSupply, "Overflow error");

        at.balances[_to] = at.balances[_to] + _value;

        at.totalSupply = at.totalSupply + _value;
    }
}
