Template.newAccountForm.events {
  'click .add-account': (event) ->
    # TODO: Better validation
    event.preventDefault();
    $context = $(event.target).parents('.add-record-form')
    # TODO: Convert to use valByName wrapper function
    accountType = valByName 'type', $context
    accountName = valByName 'name', $context
    accountBalance = if (valByName 'balance', $context).toString() isnt "" then valByName('balance', $context) else undefined
    business = checkboxStateByName('business', $context)
    bankAccountId = valByName 'bankAccountId', $context

    if not accountType or not accountName or (accountType is "payFrom" and (not accountBalance or accountBalance.toString() is ""))
      showNavError "Please select an account type and give it a name. If it's a Pay From account, enter a balance, even if that is 0."
    else
      # Add!!!
      # TODO: Reject/hide balance for non-payFrom accounts
      VirtualAccounts.insert {
        owner: Meteor.userId()
        type: accountType
        name: accountName
        balance: accountBalance
        business: business
        bankAccountId: bankAccountId
      }, (error, result) ->
        if not error
          clearFormFields $context
          showNavSuccess "New account added."
        else
          showNavError "There was a problem adding the new account. Please try again. If the problem persists, contact us."
          console.log error
}

Template.accountForm.attrs = ->
  if @_id
    return {
    class: 'edit-record-form'
    "data-target": @_id
    };
  return {
  class: 'add-record-form'
  }

Template.accountForm.bankAccounts = ->
  virtualAccounts = getVirtualAccounts undefined, undefined, {
    type: {
      $in: [ "bank" ]
    }
  }
  getAccountSelector virtualAccounts, @bankAccountId or null

Template.accountForm.events {
  'click .cancel-editing': (event) ->
    event.preventDefault()
    Session.set 'editingAccount', null
  'click .save-account': (event) ->
    event.preventDefault()
    event.stopPropagation()
    $context = $(event.target).parents('.edit-record-form')
    accountId = recordIdFromForm event

    # TODO: Reduce duplication here
    accountType = valByName 'type', $context
    accountName = valByName 'name', $context
    accountBalance = if (valByName 'balance', $context).toString() isnt "" then valByName('balance', $context) else undefined
    business = checkboxStateByName('business', $context)
    bankAccountId = valByName 'bankAccountId', $context

    if not accountType or not accountName or (accountType is "payFrom" and (not accountBalance or accountBalance.toString() is ""))
      showNavError "Please select an account type and give it a name. If it's a Pay From account, enter a balance, even if that is 0."
    else
      # Add!!!
      VirtualAccounts.update(accountId, {
        $set: {
          type: accountType
          name: accountName
          balance: accountBalance
          business: business
          bankAccountId: bankAccountId
        }
      }, (error, result) ->
        if not error
          clearFormFields $context
          showNavSuccess "<i>#{accountName}</i> updated."
          Session.set 'editingAccount', null
        else
          showNavError "There was a problem updating the account. Please try again. If the problem persists, contact us."
          console.log error
      )
}

Template.newAccountForm.virtualAccountsCount = ->
  VirtualAccounts.find({}, { reactive: false }).count()

Template.accountList.virtualAccountsCount = ->
  VirtualAccounts.find({}, { reactive: false }).count()

Template.accountList.virtualAccounts = ->
  VirtualAccounts.find().fetch()

Template.accountList.editingAccount = ->
  account = VirtualAccounts.findOne(Session.get 'editingAccount') if Session.get 'editingAccount'
  account

Template.account.thisRowBeingEdited = ->
  Session.equals('editingAccount', this._id)

Template.account.usedForExpenses = ->
  criteria = {}
  criteria["payFromAccounts.#{this._id}"] = { $exists: true }
  if Expenses.find(criteria).count() > 0 then true else false

Template.account.balance = ->
  if @type is "payFrom" and @balance then accounting.formatMoney @balance else ""

Template.account.bankAccount = ->
  getVirtualAccountName(@bankAccountId or null)

Template.account.events {
  'click .edit-account': (event) ->
    event.preventDefault()
    accountId = recordIdFromRow event
    Session.set 'editingAccount', accountId
  'click .remove-account': (event) ->
    event.preventDefault()
    accountId = recordIdFromRow event

    recordName = VirtualAccounts.findOne(accountId).name

    alertify.confirm "Are you sure you want to remove <em>#{recordName}</em>?", (event) ->
      if event
        VirtualAccounts.remove accountId, (error) ->
          if not error
            showNavSuccess "Account removed."
          else
            showNavError "I couldn't remove the account for some reason. Try again, and contact us if problems persist."
            console.log error
}

@getAccountSelector = (virtualAccounts = getVirtualAccounts(), selectedId) ->
  getCollectionSelector(virtualAccounts, selectedId)
