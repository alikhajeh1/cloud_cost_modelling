<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" indent="no" />
  <xsl:decimal-format name="n1" NaN="0" infinity=""/>

  <xsl:key name="years" match="row/year/text()" use="." />

  <xsl:template match="deployment">
    <script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
      google.setOnLoadCallback(draw_deployment_cost_chart);
      google.setOnLoadCallback(draw_cost_breakdown_chart);

      function draw_deployment_cost_chart() {
      var data = new google.visualization.DataTable();
      data.addColumn('string', 'Month');
      data.addColumn('number', 'Cost');

      data.addRows([
      <xsl:for-each select="row">
        ['<xsl:value-of select="month"/>', <xsl:value-of select="total"/>]
        <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
      ]);

      var options = {
      width: 930, height: 350,
      isStacked: true,
      vAxis: {title: 'Cost'},
      legend: {position: 'none'},
      chartArea: {left:100, top:10, width:"100%", height:"80%"}
      };

      var formatter = new google.visualization.NumberFormat();
      formatter.format(data, 1);
      var chart = new google.visualization.ColumnChart(document.getElementById('monthly_deployment_costs'));
      chart.draw(data, options);
      }

      function draw_cost_breakdown_chart() {
        var data = new google.visualization.DataTable();
        data.addColumn('string', 'Category');
        data.addColumn('number', 'Total Cost');
        data.addRows([
          ['DB/Server Hours', <xsl:value-of select="format-number(sum(//row/instance_hour), '0.00', 'n1')"/>],
          ['Storage', <xsl:value-of select="format-number(sum(//row/storage_size), '0.00', 'n1')"/>],
          ['Storage I/O', <xsl:value-of select="format-number(sum(//row/read_request) + sum(//row/write_request), '0.00', 'n1')"/>],
          ['Data Transfer', <xsl:value-of select="format-number(sum(//row/data_in) + sum(//row/data_out), '0.00', 'n1')"/>],
          ['DB Transactions', <xsl:value-of select="format-number(sum(//row/transaction), '0.00', 'n1')"/>],
          ['Additional Costs', <xsl:value-of select="format-number(sum(//row/additional_cost), '0.00', 'n1')"/>]
        ]);

        var options = {
          width: 450, height: 250,
          legend: {position: 'right', textStyle: {fontSize: 14}},
          chartArea:{left:25, top:12, width:"90%", height:"80%"}
        };

        var formatter = new google.visualization.NumberFormat();
        formatter.format(data, 1);
        var chart = new google.visualization.PieChart(document.getElementById('cost_breakdown'));
        chart.draw(data, options);
      }

      // Toggle monthly costs when user clicks on year
      $(function(){
        $('tr.monthly').hide();
        $('tr.monthly td').css('padding-left','35px');
        $('tr.yearly td a').click(function() {
          $(this).closest('tr').nextUntil('tr.yearly').toggle();
        });
      });
    </script>

    <p>All costs are show in <xsl:value-of select="user_currency"/>.
      You can change your preferred currency by <a href="/users/edit">updating your account</a> and regenerating the report.</p>
    <h5 style="text-align:center">Monthly Deployment Costs</h5>
    <div id="monthly_deployment_costs">Loading chart...</div>

    <br/>

    <div class="row">
      <div class="span8">
        <h5 style="text-align:center">Total Cost Breakdown</h5>
        <div id="cost_breakdown">Loading chart...</div>
      </div>

      <div class="span6">
        <h5 style="text-align:center">Yearly Deployment Costs</h5>
        <table class="condensed-table bordered-table zebra-striped">
          <thead>
            <tr>
              <th class="span4">Year</th>
              <th>Cost</th>
            </tr>
          </thead>

          <tbody>

            <xsl:for-each select="row/year/text()[generate-id()=generate-id(key('years',.)[1])]">
              <tr class="yearly">
                <td><a href="javascript:void(0)"><xsl:value-of select="."/></a></td>
                <td><xsl:value-of select="format-number(sum(//row[year = current()]/total), '#,##0.00', 'n1')"/></td>
              </tr>

              <xsl:for-each select="//row[year = current()]">
                <tr class="monthly">
                  <td><xsl:value-of select="month" /></td>
                  <td><xsl:value-of select="format-number(total, '#,##0.00', 'n1')" /></td>
                </tr>
              </xsl:for-each>
            </xsl:for-each>

            <tr class="yearly">
              <td><b>Total</b></td>
              <td><b><xsl:value-of select="format-number(cost, '#,##0.00', 'n1')"/></b></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </xsl:template>

</xsl:stylesheet>
