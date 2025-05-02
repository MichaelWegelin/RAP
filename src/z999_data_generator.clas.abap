CLASS z999_data_generator DEFINITION
PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS z999_data_generator IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA lt_travel TYPE SORTED TABLE OF /dmo/travel WITH UNIQUE KEY travel_id.
    SELECT * FROM /dmo/travel   "#EC CI_ALL_FIELDS_NEEDED
      INTO TABLE @lt_travel.    "#EC CI_NOWHERE

    DATA lt_travel_m TYPE STANDARD TABLE OF /dmo/travel_m.
    lt_travel_m = CORRESPONDING #( lt_travel MAPPING overall_status = status
                                                     created_by = createdby
                                                     created_at = createdat
                                                     last_changed_by = lastchangedby
                                                     last_changed_at = lastchangedat ).
    " fill in some overall status.
    LOOP AT lt_travel_m ASSIGNING FIELD-SYMBOL(<travel>).
      CASE <travel>-overall_status.
        WHEN 'B'.
          " Booked -> Accepted
          <travel>-overall_status = 'A'.
        WHEN 'P' OR 'N'.
          " Planned or New -> Open
          <travel>-overall_status = 'O'.

        WHEN OTHERS.
          " Canceled
          <travel>-overall_status = 'X'.
      ENDCASE.

    ENDLOOP.

    out->write( ' --> TRAVEL' ) ##NO_TEXT.
    DELETE FROM z999_travel.                          "#EC CI_NOWHERE
    INSERT z999_travel FROM TABLE @lt_travel_m.


    " bookings
    SELECT * FROM /dmo/booking      "#EC CI_ALL_FIELDS_NEEDED
      INTO TABLE @DATA(lt_booking). "#EC CI_NOWHERE
    DATA lt_booking_m TYPE STANDARD TABLE OF /dmo/booking_m.
    lt_booking_m = CORRESPONDING #( lt_booking ).
    " copy status and last_changed_at from travels
    lt_booking_m = CORRESPONDING #( lt_booking_m FROM lt_travel USING travel_id = travel_id
                                                  MAPPING booking_status = status
                                                          last_changed_at = lastchangedat
                                                          EXCEPT * ).

    LOOP AT lt_booking_m ASSIGNING FIELD-SYMBOL(<booking>).
      IF <booking>-booking_status = 'P'.
        <booking>-booking_status = 'N'.
      ENDIF.
    ENDLOOP.

    out->write( ' --> BOOKINGS' ) ##NO_TEXT.
    DELETE FROM z999_booking.
    INSERT z999_booking FROM TABLE @lt_booking_m.


  ENDMETHOD.
ENDCLASS.

