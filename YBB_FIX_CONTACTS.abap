*&---------------------------------------------------------------------*
*& Report YBB_FIX_CONTACTS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ybb_fix_contacts.

TYPES : BEGIN OF ty_excl_data,
          name1    TYPE text50,
          name2    TYPE text50,
          name3    TYPE text50,
          name4    TYPE text50,
          name5    TYPE text50,
          fullname TYPE text50,
          phone1   TYPE text50,
          phone2   TYPE text50,
          phone3   TYPE text50,
          phone4   TYPE text50,
          phone5   TYPE text50,
        END OF ty_excl_data,

        BEGIN OF ty_final_data,
          fullname TYPE text50,
          Mobile   TYPE text50,
        END OF ty_final_data.

DATA : gt_excl_file TYPE STANDARD TABLE OF ty_excl_data,
       gt_final     TYPE STANDARD TABLE OF ty_final_data.



SELECTION-SCREEN : BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-t01.
  PARAMETERS: p_file TYPE rlgrap-filename MEMORY ID file MODIF ID set OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b01.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM open_file_path CHANGING p_file.

START-OF-SELECTION.

  PERFORM main.
*&---------------------------------------------------------------------*
*& Form main
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM main .

  PERFORM read_excel_file.
  PERFORM format_contacts.
  PERFORM display_list.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_excel_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_excel_file .


  DATA : l_tab_raw_data TYPE truxs_t_text_data.

  CLEAR gt_excl_file.

  TRY.
*     alternate : ALSM_EXCEL_TO_INTERNAL_TABLE

      CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
        EXPORTING
          i_line_header        = abap_true
          i_tab_raw_data       = l_tab_raw_data
          i_filename           = p_file
        TABLES
          i_tab_converted_data = gt_excl_file
        EXCEPTIONS
          conversion_failed    = 1
          OTHERS               = 2.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              DISPLAY LIKE 'E'.
      ENDIF.

    CATCH cx_root INTO DATA(l_var_ref).
      DATA(l_var_text) = l_var_ref->get_text( ).
      MESSAGE l_var_text TYPE 'I' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form format_contacts
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM format_contacts .

  DATA : ls_final TYPE ty_final_data.
  DATA : lt_split TYPE string_t,
         lv_phone TYPE text50,
         lv_len   TYPE i.

  LOOP AT gt_excl_file ASSIGNING FIELD-SYMBOL(<ls_excl_file>).

    CLEAR : lv_phone, ls_final.

    ls_final-fullname = <ls_excl_file>-fullname.

    IF ls_final-fullname+0(1) = ' '.
      SHIFT ls_final-fullname LEFT DELETING LEADING space.
    ENDIF.

    DO 5 TIMES.

      CASE sy-index.
        WHEN 1.
          lv_phone = <ls_excl_file>-phone1.
        WHEN 2.
          lv_phone = <ls_excl_file>-phone2.
        WHEN 3.
          lv_phone = <ls_excl_file>-phone3.
        WHEN 4.
          lv_phone = <ls_excl_file>-phone4.
        WHEN 5.
          lv_phone = <ls_excl_file>-phone5.
      ENDCASE.

      IF lv_phone IS NOT INITIAL.
        CONDENSE lv_phone NO-GAPS.

        SPLIT lv_phone AT ':::' INTO TABLE lt_split.

        LOOP AT lt_split ASSIGNING FIELD-SYMBOL(<ls_split>).

          CONDENSE <ls_split> NO-GAPS.

          CASE strlen( <ls_split> )..
            WHEN 10.
              ls_final-mobile = <ls_split>.
              APPEND ls_final TO gt_final.
            WHEN 11.
              ls_final-mobile = <ls_split>+1(10).
              APPEND ls_final TO gt_final.
            WHEN 12.
              ls_final-mobile = <ls_split>+2(10).
              APPEND ls_final TO gt_final.
            WHEN 13.
              ls_final-mobile = <ls_split>+3(10).
              APPEND ls_final TO gt_final.
            WHEN OTHERS.
              CONTINUE.
          ENDCASE.

        ENDLOOP.

      ENDIF.

    ENDDO.

  ENDLOOP.

  SORT gt_final BY fullname mobile.

  DELETE ADJACENT DUPLICATES FROM gt_final COMPARING fullname mobile.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_list .

  DATA: lr_alv_table  TYPE REF TO cl_salv_table,
        lr_layout     TYPE REF TO cl_salv_layout,
        lr_display    TYPE REF TO cl_salv_display_settings,
        lr_selections TYPE REF TO cl_salv_selections,
        lr_functions  TYPE REF TO cl_salv_functions,
        lr_columns    TYPE REF TO cl_salv_columns_table,
        lr_column     TYPE REF TO cl_salv_column_table.

* ALV Display
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lr_alv_table
        CHANGING
          t_table      = gt_final ).
    CATCH cx_salv_msg.                                  "#EC NO_HANDLER
  ENDTRY.

* Status Bar
  lr_functions = lr_alv_table->get_functions( ).
  lr_functions->set_all( abap_true ).

* Striped Pattern
  lr_display = lr_alv_table->get_display_settings( ).
  lr_display->set_striped_pattern( cl_salv_display_settings=>true ).

* Line Selections
  lr_selections = lr_alv_table->get_selections( ).
  lr_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

* Layout
  lr_layout = lr_alv_table->get_layout( ).
  lr_layout->set_key( VALUE #( report = sy-repid ) ).
  lr_layout->set_default( abap_true ).
  lr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

* Optimize
  lr_columns = lr_alv_table->get_columns( ).
  lr_columns->set_optimize( abap_true ).

* Alv Display
  lr_alv_table->display( ).

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  OPEN_FILE_PATH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--c_var_file  text
*----------------------------------------------------------------------*
FORM open_file_path CHANGING c_var_file.

  DATA : l_var_title   TYPE string,
         l_var_extn    TYPE string,
         l_tab_filetab TYPE filetable,
         l_wa_filetab  TYPE file_table,
         l_var_initdir TYPE string,
         l_var_rc      TYPE sy-subrc.

  l_var_initdir = 'C:\Temp\'.
  l_var_title   = 'Select The Source File Path'.
  l_var_extn    = 'XLS'.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = l_var_title
      default_extension       = l_var_extn
      initial_directory       = l_var_initdir
    CHANGING
      file_table              = l_tab_filetab
      rc                      = l_var_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  IF l_var_rc = 1.
    READ TABLE l_tab_filetab INTO l_wa_filetab INDEX 1.
    IF sy-subrc = 0.
      MOVE l_wa_filetab-filename TO c_var_file.
    ENDIF.
  ENDIF.

ENDFORM. " OPEN_FILE_PATH
