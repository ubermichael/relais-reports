package Relais2::Lendingdetails;

=head1 NAME

Relais2::Lendingdetails - Instutional lending details.

=cut

use Relais2::Parameter;
use base 'Relais2::Report';
use POSIX qw(strftime);

=head2 C<< $report ->init() >>

Add start and end date, and location parameters.

=cut

sub init {
	my $self = shift;
	$self->SUPER::init(@_);
	$self->addParameter(
		Relais2::Parameter->new({
				label       => 'Start date',
				name        => 'startdate',
				bind        => ['startdate'],
				description => '',
				type        => 'date',
                                default     => strftime('%Y-%m-%d', localtime())
			}));
	$self->addParameter(
		Relais2::Parameter->new({
				label       => 'End date',
				name        => 'enddate',
				bind        => ['enddate'],
				description => '',
				type        => 'date',
                                default     => strftime('%Y-%m-%d', localtime())
			}));
	$self->addParameter(
		Relais2::Parameter->new({
				label       => 'Location',
				name        => 'loc',
				bind        => 'loc',
				description => '',
				type        => "text",
			}));
}

=head2 C<< $report->name >>

Return the name of the report.

=cut

sub name {
	return "Lending Details";
}

=head2 C<< $report->query >>

Return the SQL query.

=cut

sub query {

	# PIVOT TABLES make my head hurt.
	return <<'ENDSQL;'
SELECT
  CASE
    WHEN EXCEPTION_CODE IS NULL OR EXCEPTION_CODE = 'PNS'
      THEN 'COPY'
    WHEN EXCEPTION_CODE = 'LON'
      THEN 'LOAN'
  END AS TYPE,
  REQUEST_NUMBER,
  EXTERNAL_NUMBER,
  DELIVERY_DATE,
  TITLE
FROM
  (
    SELECT
        dbo.ID_REQUEST.REQUEST_NUMBER,
        dbo.ID_REQUEST.EXTERNAL_NUMBER,
        dbo.ID_DELIVERY.EXCEPTION_CODE,
        dbo.ID_REQUEST.TITLE,
        dbo.ID_DELIVERY.DELIVERY_DATE,
        dbo.ID_LIBRARY.LIBRARY_SYMBOL
    FROM
      dbo.ID_LIBRARY
    INNER JOIN dbo.ID_REQUEST
    ON
      dbo.ID_LIBRARY.LIBRARY_ID = dbo.ID_REQUEST.LIBRARY_ID
    LEFT OUTER JOIN dbo.ID_DELIVERY
    ON
      dbo.ID_REQUEST.REQUEST_NUMBER = dbo.ID_DELIVERY.REQUEST_NUMBER
  ) T1
WHERE
   :startdate <= delivery_date AND DATEADD(DAY, -1, delivery_date) <= :enddate
AND LIBRARY_SYMBOL = :loc
AND (EXCEPTION_CODE  IS NULL OR EXCEPTION_CODE IN ('PNS', 'LON'))
ORDER BY TYPE DESC, EXTERNAL_NUMBER ASC
ENDSQL;
}

=head2 C<< $report->columns >>

Return an arrayref of the SQL columns in the report, in the order they should appear.

=cut

sub columns {
	return [
		qw(TYPE REQUEST_NUMBER EXTERNAL_NUMBER DELIVERY_DATE TITLE)
	];
}

=head2 C<< $report->columnNames >>

Return a hashref mapping SQL column names to human readable column names.

=cut

sub columnNames {
	return {
		TYPE => 'Type',
		REQUEST_NUMBER => 'SFU ID',
		EXTERNAL_NUMBER => 'Request ID',
		DELIVERY_DATE => 'Date Filled',
		TITLE => 'Title'
	};
}

=head2 C<< $report->columnClasses() >>

Return the html classes for the columns in the report.

=cut

sub columnClasses {
	# OK. They aren't dates. But the date class has no wrap and that's what
	# I needed in a pinch.
	return {
		REQUEST_NUMBER => "date", 
		EXTERNAL_NUMBER => "date",
		DELIVERY_DATE => "date",
	};
}

=head2 C<< $report->process($row) >>

Process each row by limiting the DELIVERY_DATE column to 10 characters.

=cut

sub process {
	my $self = shift;
	my $row  = shift;
	$row->{DELIVERY_DATE} = substr($row->{DELIVERY_DATE}, 0, 10);
	return $row;
}

=head2 C<< $summary = $report->summarize($rows) >>

Produce a summary of the data.

=cut

sub summary {
	my $self = shift;
	my $rows = shift;
	my $q = shift;
	
	my $loans = 0;
	my $copies = 0;

	foreach my $row (@$rows) {
		if($row->{'TYPE'} eq 'LOAN') {
			$loans++;
		} 
		if($row->{'TYPE'} eq 'COPY') {
			$copies++;
		}
	}
	$location = $self->getParameter('loc')->value($q);
	$start = $self->getParameter('startdate')->value($q);
	$end = $self->getParameter('enddate')->value($q);
	$summary = [
		"Filled requests for $location from $start to $end",		
		"Total loans: $loans", 
		"Total copies: $copies", 
		];
	
	return $summary
}



1;
