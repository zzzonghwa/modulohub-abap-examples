@AbapCatalog.sqlViewName: 'ZMODSEATSV'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Seats by carrier (test double demo)'
define view ZMODULO_TST08_SEATS
  as select from zmodulo_flight
{
  key carrid          as Carrier,
      sum( seatsmax ) as TotalSeatsMax,
      sum( seatsocc ) as TotalSeatsOcc
}
group by carrid
