<span class="pm-ws-switcher__ws-name">ODB APIs</span>

Invite

Upgrade

ODB APIs

#### User

-   Profile
-   Trash
-   Account Settings
-   Notification Preferences
-   Active Sessions
-   Your Team

#### Team

-   Billing
-   Resource Usage
-   Audit Logs
-   Settings

### Bioquery, ODB

<a href="/me" class="pm-link docs-author" title="cywhale Weng">cywhale Weng</a>

<span id="react-select-5--value"
class="Select-multi-value-wrapper"></span>

<span class="Select-value-label">CURRENT</span>

<span class="Select-arrow-zone"><span
class="Select-arrow"></span></span>

<span class="publish-label">Published</span>

Share

Documentation

Monitors

Mocks

Changelog

Bioquery, ODB
-------------

-   -   

        <a href="#introduction" class="docs-nav__link no-select" title="Introduction">Introduction</a>

-   <span class="docs-nav__method pm-method-color-post"
    title="POST">post</span>

    <a href="#469ea712-292e-43da-b3cb-bb333677fc19" class="docs-nav__link no-select" title="bioquery site2map">bioquery site2map</a>

-   <span class="docs-nav__method pm-method-color-post"
    title="POST">post</span>

    <a href="#a2de5a8a-5452-4b9b-a486-424d534a9dd5" class="docs-nav__link no-select" title="bioquery upload user data">bioquery upload user data</a>

-   <span class="docs-nav__method pm-method-color-post"
    title="POST">post</span>

    <a href="#dcc2e890-cb5d-461e-8e9f-94b26b392514" class="docs-nav__link no-select" title="bioquery overlay environmental layer">bioquery overlay environmental layer</a>

-   -   

        <a href="#introduction" class="docs-nav__link no-select" title="Introduction">Introduction</a>

-   <span class="docs-nav__method pm-method-color-post"
    title="POST">post</span>

    <a href="#469ea712-292e-43da-b3cb-bb333677fc19" class="docs-nav__link no-select" title="bioquery site2map">bioquery site2map</a>

-   <span class="docs-nav__method pm-method-color-post"
    title="POST">post</span>

    <a href="#a2de5a8a-5452-4b9b-a486-424d534a9dd5" class="docs-nav__link no-select" title="bioquery upload user data">bioquery upload user data</a>

-   <span class="docs-nav__method pm-method-color-post"
    title="POST">post</span>

    <a href="#dcc2e890-cb5d-461e-8e9f-94b26b392514" class="docs-nav__link no-select" title="bioquery overlay environmental layer">bioquery overlay environmental layer</a>

<span id="react-select-6--value"
class="Select-multi-value-wrapper"></span>

No Environment

<span class="Select-arrow-zone"><span
class="Select-arrow"></span></span>

<span id="react-select-7--value"
class="Select-multi-value-wrapper"></span>

<span class="Select-value-label">cURL</span>

<span class="Select-arrow-zone"><span
class="Select-arrow"></span></span>

<span id="react-select-8--value"
class="Select-multi-value-wrapper"></span>

<span class="Select-value-label">Double Column</span>

<span class="Select-arrow-zone"><span
class="Select-arrow"></span></span>

Bioquery, ODB
=============

<span class="docs-desc-comments__label">Comments</span>(0)

Open API to get statitical results from bio-database, ODB, Institute of Oceanography, NTU. 
The API is in development stage and documentation is under construction. Updates will be continued. 
Now the bioquery API have following functions:

-   bioquery
-   geo2map
-   geo2wwwmap
-   txt2geojson
-   site\_intersect

<span class="pm-method-color-post">POST </span>bioquery site2map
----------------------------------------------------------------

<span class="docs-desc-comments__label">Comments</span>(0)

https://bio.odb.ntu.edu.tw/api/bioquery/png

site2map can plot sites, polygons, and overaly of environmental layer.
Basically it calls geo2map API, and can be incorporated with query
criteria from BioQuery web applications in bio.odb.ntu.edu.tw/query

#### Body

<span class="docs-request-body__mode push-half--left">formdata</span>

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<tbody>
<tr class="odd">
<td>config</td>
<td><div class="pm-markdown docs-request-table__desc">
<p>Query crieteria downloaded from BioQuery: bio.odb.ntu.edu.tw/query, or a config text, json, or yaml file.</p>
</div></td>
</tr>
<tr class="even">
<td>return_type</td>
<td>"site2map"
<div class="pm-markdown docs-request-table__desc">
<p>return data type, here, "site2map" can return png, jpeg, svg, or pdf</p>
</div></td>
</tr>
<tr class="odd">
<td>legend_pos</td>
<td>"bottom"
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Legend positon: "none" (no legend) "bottomright", "topleft", "right", "bottom", and so on</p>
</div></td>
</tr>
</tbody>
</table>

<span class="docs-example__snippet-type">Example Request</span><span
class="docs-example__response-title" title="bioquery site2map">bioquery site2map</span>

    curl --location --request POST "https://bio.odb.ntu.edu.tw/api/bioquery/png" \
      --form "config=@" \
      --form "return_type=\"site2map\"" \
      --form "legend_pos=\"bottom\""

<span class="pm-method-color-post">POST </span>bioquery upload user data
------------------------------------------------------------------------

<span class="docs-desc-comments__label">Comments</span>(0)

https://bio.odb.ntu.edu.tw/api/bioquery/png

Users can upload community abundance data of species assemblages, which
can be combined with ODB data (by 'config' parameter). This combined
data then can be used in various statistics or plotting according to
'return\_type' parameter. Data format and rules of combination see:
<https://bio.odb.ntu.edu.tw/query/?help=user_data>

#### Body

<span class="docs-request-body__mode push-half--left">formdata</span>

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<tbody>
<tr class="odd">
<td>config</td>
<td><div class="pm-markdown docs-request-table__desc">
<p>Query crieteria from bio.odb.ntu.edu.tw/query, or a config text, json, or yaml file.</p>
</div></td>
</tr>
<tr class="even">
<td>return_type</td>
<td>"site2map"
<div class="pm-markdown docs-request-table__desc">
<p>return data type, here, "site2map" can return png, jpeg, svg, or pdf</p>
</div></td>
</tr>
<tr class="odd">
<td>datasrc</td>
<td><div class="pm-markdown docs-request-table__desc">
<p>Abundance data csv file of species assemblages. Data format see: <a href="https://bio.odb.ntu.edu.tw/query/?help=user_data">https://bio.odb.ntu.edu.tw/query/?help=user_data</a></p>
</div></td>
</tr>
<tr class="even">
<td>data_mode</td>
<td>"combine"
<div class="pm-markdown docs-request-table__desc">
<p>Specify how user data combined with ODB data (from config): "indep", "combine", "combine_region" or "site". Details see:<a href="https://bio.odb.ntu.edu.tw/query/?help=user_data">https://bio.odb.ntu.edu.tw/query/?help=user_data</a></p>
</div></td>
</tr>
<tr class="odd">
<td>data_id</td>
<td>"taxon"
<div class="pm-markdown docs-request-table__desc">
<p>Specify the variable name in datasrc which means species identification (default: "taxon")</p>
</div></td>
</tr>
<tr class="even">
<td>data_val</td>
<td>"taxon_count"
<div class="pm-markdown docs-request-table__desc">
<p>Specify the variable name in datasrc which means species abundance or occurrence (default: "taxon_count")</p>
</div></td>
</tr>
<tr class="odd">
<td>data_group</td>
<td>"polyID"
<div class="pm-markdown docs-request-table__desc">
<p>Specify the grouping variable name in datasrc (default: "polyID", polygonal region ID in integer)</p>
</div></td>
</tr>
<tr class="even">
<td>geopoly</td>
<td><div class="pm-markdown docs-request-table__desc">
<p>Optional. Can be file specified longitude and latitude of polygonal regions with id, as format "csv_poly" in this example, or a character vector contains geometry text with format "lonlat_poly", bounding box with format "BBOX" (see next example), or BioQuery downloaded query text file with format "bioquery".</p>
</div></td>
</tr>
<tr class="odd">
<td>format</td>
<td>"csv_poly"
<div class="pm-markdown docs-request-table__desc">
<p>Optional but needed if specify geopoly: "csv" (CSV file with coordinates in geopoly parameter), "csv_poly" (CSV wity column of polygonal ID), "bioquery" (Config file downloaded from BioQuery: bio.odb.ntu.edu.tw/query), "bbox" (bounding box), "lonlat_poly" (string format in geopoly parameter to specify polygonal region, such as geopoly="(124,125,124.5,124,20,21,22,20);(120,121,122,122.5,120,19,20,22,22,19)"), "kml" (KML file).</p>
</div></td>
</tr>
<tr class="even">
<td>grd_sel</td>
<td>1
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Specify grid for data gridding: null (raw data), 0 (0.25-deg), 1 (0.5-deg, default), 2 (1-deg)</p>
</div></td>
</tr>
<tr class="odd">
<td>include_poly0</td>
<td>false
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Enable analysis including polyID==0, i.e., also analysis those sites which are outside the given polygonal regions (default: FALSE).</p>
</div></td>
</tr>
</tbody>
</table>

<span class="docs-example__snippet-type">Example Request</span><span
class="docs-example__response-title"
title="bioquery upload user data">bioquery upload user data</span>

    curl --location --request POST "https://bio.odb.ntu.edu.tw/api/bioquery/png" \
      --form "config=@" \
      --form "return_type=\"site2map\"" \
      --form "datasrc=@" \
      --form "data_mode=\"combine\"" \
      --form "data_id=\"taxon\"" \
      --form "data_val=\"taxon_count\"" \
      --form "data_group=\"polyID\"" \
      --form "geopoly=@" \
      --form "format=\"csv_poly\"" \

<span class="pm-method-color-post">POST </span>bioquery overlay environmental layer
-----------------------------------------------------------------------------------

<span class="docs-desc-comments__label">Comments</span>(0)

https://bio.odb.ntu.edu.tw/api/bioquery/png

Environmental (Env) factors can be specified or uploaded and used in
succeeding analysis. Specify 'envsrc' which means various sources of env
databases compiled by ODB, and 'env\_layer', i.e., the env factors
contained in this source. Each env-layer can be applied with spatially
kriging, transformed, and scaled. Details see:
<https://bio.odb.ntu.edu.tw/query/?help=bioenv>

#### Body

<span class="docs-request-body__mode push-half--left">formdata</span>

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<tbody>
<tr class="odd">
<td>config</td>
<td><div class="pm-markdown docs-request-table__desc">
<p>Query crieteria from bio.odb.ntu.edu.tw/query, or a config text, json, or yaml file.</p>
</div></td>
</tr>
<tr class="even">
<td>return_type</td>
<td>"site2map"
<div class="pm-markdown docs-request-table__desc">
<p>return data type, here, "site2map" can return png, jpeg, svg, or pdf</p>
</div></td>
</tr>
<tr class="odd">
<td>env_layer</td>
<td>"chl"
<div class="pm-markdown docs-request-table__desc">
<p>Environmental layer name that used in the specified "envsrc". See BioQuery: bio.odb.ntu.edu.tw/query to find all options for env_layer.</p>
</div></td>
</tr>
<tr class="even">
<td>envsrc</td>
<td>"nasa_neo"
<div class="pm-markdown docs-request-table__desc">
<p>Environmental source, either a file with longitude/latitude/(season)/env_layer, or a env database provided (or compiled) by ODB, NTU. Here "nasa_neo" means NASA NEO env data, and we fetch SST data. See BioQuery: bio.odb.ntu.edu.tw/query to find all options for envsrc.</p>
</div></td>
</tr>
<tr class="odd">
<td>by_season</td>
<td>true
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Plot with seasonality facets, if "season" in specified "envsrc". (default is true)</p>
</div></td>
</tr>
<tr class="even">
<td>scale_res</td>
<td>"large"
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Coastline resolution: "small", "medium", "large"</p>
</div></td>
</tr>
<tr class="odd">
<td>getenv_options</td>
<td>'{\"en_trans\":[\"1\"], \"scale_fun\":[\"log\"], \"scale_mul\":[\"1000\"], \"en_kriging\":[\"0\"]}'
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Json string that specify env_layer need transformation (en_trans: 1/0) by multipling a factor (scal_mul), by functions (scale_fun: "log", "sqrt", "exp",...), or kriging (en_kriging: 1/0). Note: kriging is time-consuming</p>
</div></td>
</tr>
<tr class="even">
<td>geopoly</td>
<td>"BBOX (110,15,130,35)"
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Plot map within a bounding box</p>
</div></td>
</tr>
<tr class="odd">
<td>format</td>
<td>"bbox"
<div class="pm-markdown docs-request-table__desc">
<p>Optional but needed if specify geopoly: "csv" (CSV file with coordinates in geopoly parameter), "csv_poly" (CSV wity column of polygonal ID), "bioquery" (Config file downloaded from BioQuery: bio.odb.ntu.edu.tw/query), "bbox" (bounding box), "lonlat_poly" (string format in geopoly parameter to specify polygonal region, such as geopoly="(124,125,124.5,124,20,21,22,20);(120,121,122,122.5,120,19,20,22,22,19)"), "kml" (KML file).</p>
</div></td>
</tr>
<tr class="even">
<td>en_poly_border</td>
<td>false
<div class="pm-markdown docs-request-table__desc">
<p>Optional. Plot outlines of polygonal region or not.</p>
</div></td>
</tr>
<tr class="odd">
<td>enlarge_poly_bbox</td>
<td>false
<div class="pm-markdown docs-request-table__desc">
<p>Optional . Enlarge plotting content to include bounding box inside.</p>
</div></td>
</tr>
</tbody>
</table>

<span class="docs-example__snippet-type">Example Request</span><span
class="docs-example__response-title"
title="bioquery overlay environmental layer">bioquery overlay environmental layer</span>

    curl --location --request POST "https://bio.odb.ntu.edu.tw/api/bioquery/png" \
      --form "return_type=\"site2map\"" \
      --form "env_layer=\"chl\"" \
      --form "envsrc=\"nasa_neo\"" \
      --form "by_season=true" \
      --form "scale_res=\"large\"" \
      --form "getenv_options='{\\\"en_trans\\\":[\\\"1\\\"], \\\"scale_fun\\\":[\\\"log\\\"], \\\"scale_mul\\\":[\\\"1000\\\"], \\\"en_kriging\\\":[\\\"0\\\"]}'" \
      --form "geopoly=\"BBOX (110,15,130,35)\"" \
      --form "format=\"bbox\"" \
      --form "en_poly_border=false" \
