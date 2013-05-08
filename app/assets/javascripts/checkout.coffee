$ ->
    marginTop = 78
    checkoutCart = $('#checkout-cart.step')
    checkoutShipping = $('#checkout-shipping.step')
    checkoutBilling = $('#checkout-billing.step')
    sections = $('#checkout .step')

    shippingAddress = new @Form $('#form-shipping-address')
    billingMethod = new @Form $('#form-billing-method')

    # Fill form summary with form data
    fillSummary = (form, summaryList) ->
        form.find(':input').not(':disabled').each ->
            value = if $(this).is('select') then $(this).find(':selected').text() else $(this).val()
            place = summaryList.find('[data-form=' + $(this).attr("name") + ']')

            if place.length > 0
                # If there is a list element for this value, set here the data
                place.text(value)
            else
                # Otherwise append a new list element
                summaryList.append("<li>" + value + "</li>")

    # Load the payment method list
    loadPaymentNetworks = (listElement) ->
        listElement.load("checkout/payment/network", ->

            # Disable all form elements until selected
            listElement.find('.payment-network-form :input').attr('disabled', 'disabled')

            # Add events on change selected payment method
            listElement.find('.payment-network').has('a[data-toggle=tab]').click( ->
                active = listElement.find($(this).find('a[data-toggle=tab]').attr("href"))
                inactive = active.siblings()

                # Disable form elements of inactive networks
                inactive.find(':input').attr('disabled', 'disabled')

                # Enable form elements of selected network
                active.find(':input').removeAttr('disabled')
            )

            # Show tooltip on hovering input with hint
            listElement.find('.hint-message').hover( ->
                id = $(this).parent().attr("for") + "-hint"
                $('#' + id + '.hint').show()
            , ->
                id = $(this).parent().attr("for") + "-hint"
                $('#' + id + '.hint').hide()
            )
        )

    # Jump to the next section form
    nextStep = (focused) ->
        next = $('#checkout .step.disabled').filter(':first')

        # Set focused section as visited
        focused.removeClass("disabled current").addClass("visited")

        if next.length > 0
            # Set first disabled section as current
            next.removeClass("visited disabled").addClass("current")

            # Set scroll position to next section
            $('html, body').animate scrollTop: next.offset().top - marginTop, 'slow'
        else
            # Set submit button visible
            $('#checkout-footer button[type=submit]').not(':visible').fadeIn()


    # Bind 'change' button click event to allow editing a section form
    $('#checkout .btn-edit').click( ->
        selected = $(this).parentsUntil('.step').parent()
        focused = sections.not('.disabled').not('.visited')

        # Set focused section as disabled unless it is also current section
        if focused.hasClass("current")
            focused.addClass("disabled")
        else
            focused.addClass("visited")

        # Set selected section as current
        selected.removeClass("visited disabled")

        # Set scroll position to selected section
        $('html, body').animate scrollTop: selected.offset().top - marginTop, 'slow'
    )

    # Bind cart 'next step' click event to 'next step' functionality
    checkoutCart.find('.btn-next').click( ->
        nextStep(checkoutCart)
    )

    # Bind shipping address submit event to 'set address' and 'next step' functionality
    shippingAddress.form.submit( ->
        # Remove alert messages
        shippingAddress.removeAllMessages()

        # Validate form client side
        return false unless shippingAddress.validateRequired()

        # Send new data to server
        url = shippingAddress.form.attr("action")
        method = shippingAddress.form.attr("method")
        data = shippingAddress.form.serialize()

        shippingAddress.submit(url, method, data, ->
            # Load payment networks once we have shipping information
            loadPaymentNetworks($('#payment-networks'))

            # Fill form summary data
            fillSummary($('#shipping-address-form'), $('#shipping-address-summary'))

            # Go to next section
            nextStep(checkoutShipping)
        )

        # Disable form submit
        return false
    )

    # Bind billing 'next step' click event to 'validate form' and 'next step' functionality
    billingMethod.inputs.filter('.btn-next').click( ->
        # Remove alert messages
        billingMethod.removeAllMessages()
        billingMethod.reload()

        # Validate form client side
        return false unless billingMethod.validateRequired(true)

        # Fill form summary data
        fillSummary($('#billing-method-form'), $('#billing-method-summary'))

        # Go to next section
        nextStep(checkoutBilling)
    )
