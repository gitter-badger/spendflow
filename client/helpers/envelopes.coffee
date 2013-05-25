Template.envelopeForm.virtualAccounts = ->
  virtualAccounts = getVirtualAccounts()
  self = this

  selectOptions = for virtualAccount in virtualAccounts
    {
      optionValue: virtualAccount._id
      optionText: virtualAccount.name
      selected: if virtualAccount._id is self.virtualAccountId then true else false
    }

Template.envelopeList.editingEnvelope = ->
  envelope = Envelopes.findOne(Session.get 'editingEnvelope') if Session.get 'editingEnvelope'
  envelope

Template.envelopeList.envelopes = ->
  Envelopes.find().fetch()

Template.envelope.virtualAccount = ->
  VirtualAccounts.findOne(this.virtualAccountId).name

Template.envelopeForm.events {
  'click .add-envelope': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.add-record-form')

    virtualAccountId = valByName "virtualAccountId", $context
    rate = valByName "rate", $context
    enabledByDefault = checkboxStateByName "enabledByDefault", $context
    active = checkboxStateByName "active", $context

    if not virtualAccountId or not rate
      showNavError "Please pick an account and enter a rate."
    else
      Envelopes.insert {
        owner: getCurrentUserId()
        virtualAccountId: virtualAccountId
        rate: rate
        enabledByDefault: enabledByDefault
        active: active
      }, (error, result) ->
        if not error
          $('input, select', $('.add-record-form')).val("")
          showNavSuccess "New envelope added."
        else
          showNavError "There was a problem adding the new envelope. Please try again. If the problem persists, contact us."
          console.log error
  'click .save-envelope': (event) ->
    event.preventDefault()
    $context = $(event.target).parents('.edit-record-form')
    envelopeId = recordIdFromForm event

    virtualAccountId = valByName "virtualAccountId", $context
    rate = valByName "rate", $context
    enabledByDefault = checkboxStateByName "enabledByDefault", $context
    active = checkboxStateByName "active", $context

    if not virtualAccountId or not rate
      showNavError "Please pick an account and enter a rate."
    else
      Envelopes.update envelopeId, {
        $set: {
          virtualAccountId: virtualAccountId
          rate: rate
          enabledByDefault: enabledByDefault
          active: active
        }
      }, (error, result) ->
        if not error
          $('input, select', $('.edit-record-form')).val("")
          showNavSuccess "Envelope updated."
          Session.set 'editingEnvelope', null
        else
          showNavError "There was a problem updating the envelope. Please try again. If the problem persists, contact us."
          console.log error
  'click .cancel-editing': (event) ->
    event.preventDefault()
    Session.set 'editingEnvelope', null
}

Template.envelope.thisRowBeingEdited = ->
  Session.equals('editingEnvelope', this._id)

Template.envelope.events {
  'click .edit-envelope': (event) ->
    envelopeId = recordIdFromRow event
    Session.set 'editingEnvelope', envelopeId
  'click .remove-envelope': (event) ->
    envelopeId = recordIdFromRow event
    Envelopes.remove envelopeId, (error) ->
      if not error
        showNavSuccess "Envelope removed."
      else
        showNavError "I couldn't remove the envelope for some reason. Try again, and contact us if problems persist."
        console.log error
}
