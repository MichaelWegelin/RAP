CLASS lhc_Z000_I_TRAVEL_1 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS validateagency FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateagency.
    METHODS validatebookingfee FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatebookingfee.
    METHODS validatecurrencycode FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatecurrencycode.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatecustomer.
    METHODS validatedates FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatedates.
    METHODS validatestatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatestatus.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calculatetotalprice.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~accepttravel RESULT result.
    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejecttravel RESULT result.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_booking.

ENDCLASS.

CLASS lhc_Z000_I_TRAVEL_1 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA:
      entity        TYPE STRUCTURE FOR CREATE Z000_I_TRAVEL_1,
      travel_id_max TYPE /dmo/travel_id.

    " Ensure Travel ID is not set yet (idempotent)- must be checked when BO is draft-enabled
    LOOP AT entities INTO entity WHERE TravelID IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    DATA(entities_wo_travelid) = entities.
    DELETE entities_wo_travelid WHERE TravelID IS NOT INITIAL.

    " Get Numbers
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines( entities_wo_travelid ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        = DATA(number_range_return_code)
            returned_quantity = DATA(number_range_returned_quantity)
        ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #(  %cid = entity-%cid
                           %key = entity-%key
                           %msg = lx_number_ranges
                        ) TO reported-travel.
          APPEND VALUE #(  %cid = entity-%cid
                           %key = entity-%key
                        ) TO failed-travel.
        ENDLOOP.
        EXIT.
    ENDTRY.

    CASE number_range_return_code.
      WHEN '1'.
        " 1 - the returned number is in a critical range (specified under “percentage warning” in the object definition)
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                      textid = /dmo/cm_flight_messages=>number_range_depleted
                                      severity = if_abap_behv_message=>severity-warning )
                        ) TO reported-travel.
        ENDLOOP.

      WHEN '2' OR '3'.
        " 2 - the last number of the interval was returned
        " 3 - if fewer numbers are available than requested,  the return code is 3
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                      textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                      severity = if_abap_behv_message=>severity-warning )
                        ) TO reported-travel.
          APPEND VALUE #( %cid        = entity-%cid
                          %key        = entity-%key
                          %fail-cause = if_abap_behv=>cause-conflict
                        ) TO failed-travel.
        ENDLOOP.
        EXIT.
      ENDCASE.

    " At this point ALL entities get a number!
    ASSERT number_range_returned_quantity = lines( entities_wo_travelid ).

    travel_id_max = number_range_key - number_range_returned_quantity.

    " Set Travel ID
    LOOP AT entities_wo_travelid INTO entity.
      travel_id_max += 1.
      entity-TravelID = travel_id_max .

      APPEND VALUE #( %cid  = entity-%cid
                      %key  = entity-%key
                    ) TO mapped-travel.
    ENDLOOP.


  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.
      DATA: max_booking_id TYPE /dmo/booking_id.

    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel BY \_booking
        FROM CORRESPONDING #( entities )
        LINK DATA(bookings).

    " Loop over all unique TravelIDs
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>) GROUP BY <travel>-TravelID.

      " Get highest booking_id from existing bookings belonging to travel
      max_booking_id = REDUCE #( INIT max = CONV /dmo/booking_id( '0' )
                                 FOR  booking IN bookings USING KEY entity WHERE ( source-TravelID  = <travel>-TravelID )
                                 NEXT max = COND /dmo/booking_id( WHEN booking-target-BookingID > max
                                                                    THEN booking-target-BookingID
                                                                    ELSE max )
                               ).
      " Get highest assigned booking_id from incoming entities, eg from internal operations
      max_booking_id = REDUCE #( INIT max = max_booking_id
                                 FOR  entity IN entities USING KEY entity WHERE ( TravelID  = <travel>-TravelID )
                                 FOR  target IN entity-%target
                                 NEXT max = COND /dmo/booking_id( WHEN   target-BookingID > max
                                                                    THEN target-BookingID
                                                                    ELSE max )
                               ).

      " Assign new booking-ids if not already assigned
      LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<booking_wo_numbers>).
        APPEND CORRESPONDING #( <booking_wo_numbers> ) TO mapped-booking ASSIGNING FIELD-SYMBOL(<mapped_booking>).
        IF <booking_wo_numbers>-BookingID IS INITIAL.
          max_booking_id += 10 .
          <mapped_booking>-BookingID = max_booking_id .
        ENDIF.
      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateAgency.
      " Read relevant travel instance data
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
    ENTITY travel
     FIELDS ( AgencyID )
     WITH CORRESPONDING #(  keys )
    RESULT DATA(travels).

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.

    " Optimization of DB select: extract distinct non-initial agency IDs
    agencies = CORRESPONDING #(  travels DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.
    IF  agencies IS NOT INITIAL.

      " check if agency ID exist
      SELECT FROM /dmo/agency FIELDS agency_id
        FOR ALL ENTRIES IN @agencies
        WHERE agency_id = @agencies-agency_id
        INTO TABLE @DATA(agencies_db).
    ENDIF.

    " Raise msg for non existing and initial agency id
    LOOP AT travels INTO DATA(travel).
      IF travel-AgencyID IS INITIAL
         OR NOT line_exists( agencies_db[ agency_id = travel-AgencyID ] ).

        APPEND VALUE #(  %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #(  %tky = travel-%tky
                         %msg      = NEW /dmo/cm_flight_messages(
                                          textid    = /dmo/cm_flight_messages=>agency_unkown
                                          agency_id = travel-AgencyID
                                          severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateBookingFee.
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
        FIELDS ( BookingFee )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel) WHERE BookingFee < 0.
      " Raise message for booking fee < 0
      APPEND VALUE #( %tky                 = travel-%tky ) TO failed-travel.
      APPEND VALUE #( %tky                 = travel-%tky
                      %msg                 = NEW /dmo/cm_flight_messages(
                                                     textid      = /dmo/cm_flight_messages=>booking_fee_invalid
                                                     severity    = if_abap_behv_message=>severity-error )
                      %element-BookingFee = if_abap_behv=>mk-on
                    ) TO reported-travel.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCurrencyCode.
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
        FIELDS ( CurrencyCode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    DATA: currencies TYPE SORTED TABLE OF I_Currency WITH UNIQUE KEY currency.

    currencies = CORRESPONDING #(  travels DISCARDING DUPLICATES MAPPING currency = CurrencyCode EXCEPT * ).
    DELETE currencies WHERE currency IS INITIAL.

    IF currencies IS NOT INITIAL.
      SELECT FROM I_Currency FIELDS currency
        FOR ALL ENTRIES IN @currencies
        WHERE currency = @currencies-currency
        INTO TABLE @DATA(currency_db).
    ENDIF.


    LOOP AT travels INTO DATA(travel).
      IF travel-CurrencyCode IS INITIAL.
        " Raise message for empty Currency
        APPEND VALUE #( %tky                   = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky                   = travel-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid    = /dmo/cm_flight_messages=>currency_required
                                                        severity  = if_abap_behv_message=>severity-error )
                        %element-CurrencyCode = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ELSEIF NOT line_exists( currency_db[ currency = travel-CurrencyCode ] ).
        " Raise message for not existing Currency
        APPEND VALUE #( %tky                   = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky                   = travel-%tky
                        %msg                   = NEW /dmo/cm_flight_messages(
                                                        textid        = /dmo/cm_flight_messages=>currency_not_existing
                                                        severity      = if_abap_behv_message=>severity-error
                                                        currency_code = travel-CurrencyCode )
                        %element-CurrencyCode = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.
      " Read relevant travel instance data
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
    ENTITY travel
     FIELDS ( CustomerId )
     WITH CORRESPONDING #(  keys )
    RESULT DATA(travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.
    IF customers IS NOT INITIAL.

      " Check if customer ID exists
      SELECT FROM /dmo/customer FIELDS customer_id
        FOR ALL ENTRIES IN @customers
        WHERE customer_id = @customers-customer_id
        INTO TABLE @DATA(customers_db).
    ENDIF.
    " Raise msg for non existing and initial customer id
    LOOP AT travels INTO DATA(travel).
      IF travel-CustomerID IS INITIAL
         OR NOT line_exists( customers_db[ customer_id = travel-CustomerID ] ).

        APPEND VALUE #(  %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #(  %tky = travel-%tky
                         %msg      = NEW /dmo/cm_flight_messages(
                                         customer_id = travel-CustomerID
                                         textid      = /dmo/cm_flight_messages=>customer_unkown
                                         severity    = if_abap_behv_message=>severity-error )
                         %element-CustomerID = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      IF travel-EndDate < travel-EndDate.  "end_date before begin_date

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                   textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                   severity   = if_abap_behv_message=>severity-error
                                   begin_date = travel-BeginDate
                                   end_date   = travel-EndDate
                                   travel_id  = travel-TravelId )
                        %element-BeginDate   = if_abap_behv=>mk-on
                        %element-EndDate     = if_abap_behv=>mk-on
                     ) TO reported-travel.

      ELSEIF travel-BeginDate < cl_abap_context_info=>get_system_date( ).  "begin_date must be in the future

        APPEND VALUE #( %tky        = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid   = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                    severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate  = if_abap_behv=>mk-on
                        %element-EndDate    = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD validateStatus.
      READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
        ENTITY travel
          FIELDS ( OverallStatus )
          WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      CASE travel-OverallStatus.
        WHEN 'O'.  " Open
        WHEN 'X'.  " Cancelled
        WHEN 'A'.  " Accepted

        WHEN OTHERS.
          APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

          APPEND VALUE #( %tky = travel-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>status_invalid
                                     severity = if_abap_behv_message=>severity-error
                                     status = travel-OverallStatus )
                          %element-OverallStatus = if_abap_behv=>mk-on
                        ) TO reported-travel.
      ENDCASE.

    ENDLOOP.
  ENDMETHOD.

  METHOD calculateTotalPrice.
    MODIFY ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
        EXECUTE recalctotalprice
        FROM CORRESPONDING #( keys ).
  ENDMETHOD.

  METHOD ReCalcTotalPrice.
    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: amounts_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    " Read all relevant travel instances.
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
         ENTITY travel
            FIELDS ( BookingFee CurrencyCode )
            WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

    " Read all associated bookings and add them to the total price.
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel BY \_booking
        FIELDS ( FlightPrice CurrencyCode )
      WITH CORRESPONDING #( travels )
      RESULT DATA(bookings).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      " Set the start for the calculation by adding the booking fee.
      amounts_per_currencycode = VALUE #( ( amount        = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).


      LOOP AT bookings INTO DATA(booking) USING KEY id WHERE   TravelID = <travel>-TravelID
                                                       AND     CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amount_per_currencycode( amount        = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode
                                                ) INTO amounts_per_currencycode.
      ENDLOOP.

      DELETE amounts_per_currencycode WHERE currency_code IS INITIAL.

      CLEAR <travel>-TotalPrice.
      LOOP AT amounts_per_currencycode INTO DATA(amount_per_currencycode).
        " If needed do a Currency Conversion
        IF amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
             EXPORTING
               iv_amount                   =  amount_per_currencycode-amount
               iv_currency_code_source     =  amount_per_currencycode-currency_code
               iv_currency_code_target     =  <travel>-CurrencyCode
               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
             IMPORTING
               ev_amount                   = DATA(total_booking_price_per_curr)
            ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " write back the modified total_price of travels
    MODIFY ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
        UPDATE FIELDS ( TotalPrice )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
         FIELDS (  TravelID OverallStatus )
         WITH CORRESPONDING #( keys )
       RESULT DATA(travels)
       FAILED failed.


    result = VALUE #( FOR travel IN travels
                       ( %tky                           = travel-%tky
                         %features-%action-rejecttravel = COND #( WHEN travel-OverallStatus = 'X'
                                                                  THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled  )
                         %features-%action-accepttravel = COND #( WHEN travel-OverallStatus = 'A'
                                                                  THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                         %assoc-_booking                = COND #( WHEN travel-OverallStatus = 'X'
                                                                  THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                      ) ).
  ENDMETHOD.

  METHOD acceptTravel.
    " Modify in local mode: BO-related updates that are not relevant for authorization checks
    MODIFY ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
           ENTITY travel
              UPDATE FIELDS ( OverallStatus )
                 WITH VALUE #( FOR key IN keys ( %tky      = key-%tky
                                                 OverallStatus = 'A' ) ). " Accepted

    " Read changed data for action result
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
         ALL FIELDS WITH
         CORRESPONDING #( keys )
       RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky      = travel-%tky
                                              %param    = travel ) ).

  ENDMETHOD.

  METHOD rejectTravel.
    MODIFY ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
           ENTITY travel
              UPDATE FIELDS ( OverallStatus )
                 WITH VALUE #( FOR key IN keys ( %tky      = key-%tky
                                                 OverallStatus = 'X' ) ). " Rejected


    " read changed data for result
    READ ENTITIES OF Z000_I_TRAVEL_1 IN LOCAL MODE
      ENTITY travel
         ALL FIELDS WITH
         CORRESPONDING #( keys )
       RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky      = travel-%tky
                                              %param    = travel ) ).

  ENDMETHOD.

ENDCLASS.
