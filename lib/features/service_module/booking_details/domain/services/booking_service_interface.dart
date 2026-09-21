/// `all` mirrors the generic order list's "All" tab; `running` covers every
/// non-final status; `previous` covers completed/canceled/refund history.
enum BookingListType { all, running, previous }

abstract class BookingServiceInterface {}
