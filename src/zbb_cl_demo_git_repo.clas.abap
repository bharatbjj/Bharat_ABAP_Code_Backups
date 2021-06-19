CLASS zbb_cl_demo_git_repo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA : gv_name TYPE /dmo/agency_name.

    METHODS: get_name IMPORTING iv_agency_id   TYPE /dmo/agency_id
                      EXPORTING ev_agency_name TYPE /dmo/agency_name.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zbb_cl_demo_git_repo IMPLEMENTATION.
  METHOD get_name.
    CHECK iv_agency_id IS NOT INITIAL.

    SELECT SINGLE FROM /DMO/I_Agency
    FIELDS Name
     WHERE  AgencyID = @iv_agency_id
     INTO @ev_agency_name.

    gv_name = ev_agency_name.

  ENDMETHOD.

ENDCLASS.
