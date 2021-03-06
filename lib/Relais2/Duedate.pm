package Relais2::Duedate;

use base 'Relais2::Report';

=head1 NAME

Relais2::Duedate - Report books past their due.

=cut

=head2 C<< $report->name >>

Return the name of the report.

=cut

sub name {
	return "Due date";
}

=head2 C<< $report->query >>

Return the SQL query.

=cut

sub query {

	return << 'ENDSQL;'
SELECT     
	dbo.ID_REQUEST.REQUEST_NUMBER, dbo.ID_REQUEST.TITLE, dbo.ID_PATRON.PATRON_NAME, 
	dbo.ID_PATRON.PATRON_SURNAME, dbo.ID_PATRON.PATRON_TYPE, dbo.ID_LOAN_TRACKING.DUE_DATE, 
	dbo.ID_DELIVERY.SUPPLIER_CODE_1
FROM
    dbo.ID_REQUEST 
    	INNER JOIN dbo.ID_PATRON 
    		ON dbo.ID_REQUEST.PATRON_ID = dbo.ID_PATRON.PATRON_ID 
    	INNER JOIN dbo.ID_LOAN_TRACKING 
    		ON dbo.ID_REQUEST.REQUEST_NUMBER = dbo.ID_LOAN_TRACKING.REQUEST_NUMBER 
    		AND dbo.ID_LOAN_TRACKING.LOAN_STATUS = 'LON'
    	INNER JOIN dbo.ID_DELIVERY ON dbo.ID_REQUEST.REQUEST_NUMBER = dbo.ID_DELIVERY.REQUEST_NUMBER                      
ENDSQL;
}

=head2 C<< $report->columns >>

Return an arrayref of the SQL columns in the report, in the order they should appear.

=cut

sub columns {
	return [qw(
		REQUEST_NUMBER TITLE NAME PATRON_TYPE DUE_DATE SUPPLIER_CODE_1
	)];
}

=head2 C<< $report->process($row) >>

Process each row by limiting the DUE_DATE column to 10 characters.

=cut

sub process {
	my $self = shift;
	my $row = shift;
	$row->{DUE_DATE} = substr($row->{DUE_DATE}, 0, 10);
	$row->{NAME} = $row->{PATRON_SURNAME} . ', ' . $row->{PATRON_NAME}; 
	return $row;
}

=head2 C<< $report->columnNames >>

Return a hashref mapping SQL column names to human readable column names.

=cut

sub columnNames {
	return {
		REQUEST_NUMBER => "Request number", 
		TITLE => "Title",
		NAME => 'Patron',
		PATRON_TYPE => "Status",
		DUE_DATE => "Due date",
		SUPPLIER_CODE_1 => "Supplier"
	};
}

=head2 C<< $report->columnClasses() >>

Return the html classes for the columns in the report.

=cut

sub columnClasses {
	return {
		REQUEST_NUMBER => "requestnum", 
		DUE_DATE => "date",
	};
}


1;