module RDoc
module Page
FONTS = ""
METHOD_LIST = ""
SRC_PAGE = ""
FILE_PAGE = ""
CLASS_PAGE = ""
FR_INDEX_BODY = "!INCLUDE!"

STYLE = ""
JAVASCRIPT = ""


FILE_INDEX = <<-END_FILE_INDEX
START:entries
<a href="%href%">%name%</a><br />
END:entries
END_FILE_INDEX
METHOD_INDEX = "methods"
CLASS_INDEX = <<-END_CLASS_INDEX
<div id="class_index">
#{FILE_INDEX}
</div>
END_CLASS_INDEX

BODY = <<-END_BODY
<html>
<head>
  <title>%title% - Braintree Ruby Documentation</title>
<style type="text/css">
#{File.read(File.dirname(__FILE__) + "/reset.css")}
#{File.read(File.dirname(__FILE__) + "/text.css")}
#{File.read(File.dirname(__FILE__) + "/960.css")}
#{File.read(File.dirname(__FILE__) + "/braintree.css")}
</style>
<!-- STYLE_URL = %style_url% -->
</head>
<body>
<div class="container_16" id="wrapper">
<div class="grid_16">
  <div class="grid_14 alpha">
    <a href="BASE_URL">
      <img src="BASE_URL/ruby.png" alt="Ruby" />
      <img src="BASE_URL/braintree.gif" alt="Braintree" />
    </a>
  </div>
  <div class="grid_2 omega">
  </div>
</div>
<hr style="background-color: #999;" />
<div class="clear"></div>
<div class="grid_4" id="navigation">
  <div class="box">
    <h3>Files</h3>
    <ul>
      <li><a href="BASE_URL/files/README_rdoc.html">README</a></li>
      <li><a href="BASE_URL/files/LICENSE.html">LICENSE</a></li>
    </ul>
  </div>

  <div class="box">
    <h3>Resources</h3>
    <ul>
      <li><a href="BASE_URL/classes/Braintree/Transaction.html">Transaction</a></li>
      <li><a href="BASE_URL/classes/Braintree/Customer.html">Customer</a></li>
      <li><a href="BASE_URL/classes/Braintree/CreditCard.html">CreditCard</a></li>
      <li><a href="BASE_URL/classes/Braintree/Address.html">Address</a></li>
    </ul>
  </div>

  <div class="box">
    <h3>Classes</h3>
    <ul>
      <li><a href="BASE_URL/classes/Braintree/Configuration.html">Configuration</a></li>
      <li><a href="BASE_URL/classes/Braintree/SuccessfulResult.html">SuccessfulResult</a></li>
      <li><a href="BASE_URL/classes/Braintree/ErrorResult.html">ErrorResult</a></li>
      <li><a href="BASE_URL/classes/Braintree/Errors.html">Errors</a></li>
      <li><a href="BASE_URL/classes/Braintree/ValidationErrorCollection.html">ValidationErrorCollection</a></li>
      <li><a href="BASE_URL/classes/Braintree/PagedCollection.html">PagedCollection</a></li>
      <li><a href="BASE_URL/classes/Braintree/TransparentRedirect.html">TransparentRedirect</a></li>
      <li><a href="BASE_URL/classes/Braintree/Version.html">Version</a></li>
      <li><a href="BASE_URL/classes/Braintree/Test/CreditCardNumbers.html">Test::CreditCardNumbers</a></li>
      <li><a href="BASE_URL/classes/Braintree/Test/TransactionAmounts.html">Test::TransactionAmounts</a></li>
    </ul>
  </div>

  <div class="box">
    <h3>Error Codes</h3>
    <ul>
      <li><a href="BASE_URL/classes/Braintree/ErrorCodes.html">ErrorCodes</a></li>
      <li><a href="BASE_URL/classes/Braintree/ErrorCodes/Transaction.html">ErrorCodes::Transaction</a></li>
      <li><a href="BASE_URL/classes/Braintree/ErrorCodes/Customer.html">ErrorCodes::Customer</a></li>
      <li><a href="BASE_URL/classes/Braintree/ErrorCodes/CreditCard.html">ErrorCodes::CreditCard</a></li>
      <li><a href="BASE_URL/classes/Braintree/ErrorCodes/Address.html">ErrorCodes::Address</a></li>
    </ul>
  </div>

  <div class="box">
    <h3>Exceptions</h3>
    <ul>
      <li><a href="BASE_URL/classes/Braintree/BraintreeError.html">BraintreeError</a></li>
      <li><a href="BASE_URL/classes/Braintree/AuthenticationError.html">AuthenticationError</a></li>
      <li><a href="BASE_URL/classes/Braintree/AuthorizationError.html">AuthorizationError</a></li>
      <li><a href="BASE_URL/classes/Braintree/ConfigurationError.html">ConfigurationError</a></li>
      <li><a href="BASE_URL/classes/Braintree/DownForMaintenanceError.html">DownForMaintenanceError</a></li>
      <li><a href="BASE_URL/classes/Braintree/ForgedQueryString.html">ForgedQueryString</a></li>
      <li><a href="BASE_URL/classes/Braintree/NotFoundError.html">NotFoundError</a></li>
      <li><a href="BASE_URL/classes/Braintree/ServerError.html">ServerError</a></li>
      <li><a href="BASE_URL/classes/Braintree/SSLCertificateError.html">SSLCertificateError</a></li>
      <li><a href="BASE_URL/classes/Braintree/UnexpectedError.html">UnexpectedError</a></li>
      <li><a href="BASE_URL/classes/Braintree/ValidationsFailed.html">ValidationsFailed</a></li>
    </ul>
  </div>
</div>
<div class="grid_12">
<h1>%title%</h1>

IF:description
  <hr />
  <div class="description">
    %description%
  </div>
ENDIF:description

START:sections
IF:sectitle
<div class="sectiontitle"><a nem="%secsequence%">%sectitle%</a></div>
IF:seccomment
<div class="description">
%seccomment%
</div>
ENDIF:seccomment
ENDIF:sectitle

IF:constants
<hr />
<div class="sectiontitle">Constants</div>
<table>
<thead><tr><th>Constant</th><th>Value</th></tr></thead>
<tboyd>
START:constants
<tr><td>%name%</td><td>%value%</td></tr>
END:constants
</tbody>
</table>
ENDIF:constants

IF:attributes
<hr />
<div class="sectiontitle">Attributes</div>
<table>
START:attributes
<tr>
<td class='attr-rw'>
IF:rw
[%rw%]
ENDIF:rw
</td>
<td class='attr-name'>%name%</td>
<td class='attr-desc'>%a_desc%</td>
</tr>
END:attributes
</table>
ENDIF:attributes

IF:method_list
START:method_list
IF:methods
<hr />
<div class="sectiontitle">%type% %category% Methods</div>
START:methods
<div class="method">
<div class="title">
IF:callseq
<a name="%aref%"></a><b>%callseq%</b>
ENDIF:callseq
IFNOT:callseq
<a name="%aref%"></a><b>%name%</b>%params%
ENDIF:callseq
</div><!-- end class=title -->
IF:m_desc
<div class="description"> %m_desc% </div>
ENDIF:m_desc
</div><!-- end class=method -->
END:methods
ENDIF:methods
END:method_list
ENDIF:method_list
END:sections
</div><!-- end grid_13 -->

<hr />
<div class="grid_16">&copy; Copyright 2009 Braintree Payment Solutions. All Rights Reserved.</div>

<div class="clear"></div>
</div><!-- end wrapper -->
</body>
</html>
END_BODY

INDEX = <<-END_INDEX
<html>
  <head>
    <title>%title%</title>
    <meta http-equiv="refresh" content="0;url=%initial_page%" />
  </head>
  <body>
    <div>You are being redirected to <a href="%initial_page%">%initial_page%</a></div>
  </body>
</html>
END_INDEX
end
end
