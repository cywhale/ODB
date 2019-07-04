############### Authentication problem to access postman url not solved #######
############### so temporarily, just save html from chrome, save as a test.html
############### Postman API published in: http://bit.ly/2J96jza
############### update: 201907

library(rmarkdown)

pre_infile <- "test"
fo <- paste0(pre_infile,"_out.md") #outfile, append to this file, so need to initially clear it

my_writef <- function(line, file, append=TRUE) {
  write(line,file=file,append=append)
}

pandoc_convert(paste0(pre_infile,".html"), to = "markdown_strict", 
               output=paste0(pre_infile,".md"))

px <- readLines(paste0(pre_infile,".md"))
ex_count <- 1L ### example count, create anchor in html
ex_anchor <- 'curl'
curl_flag <- FALSE ## insert Response after curl example
skip_flag <- TRUE
drop1_comment <- '<span class="docs-desc-comments__label">Comments' ## do not need this line
section_sep <- '<span class="pm-method-color-post">POST' ## every POST (or GET) is a new section
section_keyword <- 'POST'
section_anchor <- 'api'
api_url <- 'https://bio.odb.ntu.edu.tw/api/bioquery/'
ex_pre <- 'Example Request'
#ex_keyword <- 'curl' # use ex_anchor
body_keyword <- 'Body'
hyphen_sep <- '--------------------------------------'
table_sep <- '</table>'

file_pre <- "@" ## change @ to @Your_File_Path

#### manual add for figure caption 
fig_cap <- c("Bioquery site2map with polygonal region", #for ex01
             "User data combined with ODB data with regions respectively",
             "SST, or other env layer overlay on map with seasonality")
fig_dir <- "img/"
fig_pre <- "ex"
fig_suffx <- "_resp"
fig_type <- "png"

if (length(px)>0) {
  newlinex <- function(file=fo) { my_writef(c("   "), file) } #<br> line break
  hlinex <- function(file=fo) {
    newlinex()
    my_writef(c("---   "), file) 
    newlinex()
  } #<hr> horizontal line
  
  for (i in seq_along(px)) {
    if (skip_flag & !grepl(drop1_comment, px[i])) { #first detect comment is the start of html content we need
      next
    } else {
      if (skip_flag) {
        print(paste0("Find content in row: ",i))
        skip_flag <- FALSE
        newlinex()
        next
      }
      if (grepl(drop1_comment, px[i])) { 
        print(paste0("drop comment in row: ",i))
        next 
      }
      if (grepl(api_url, px[i]) & !any(grepl(ex_anchor, px[i]))) { #curl in line is example, not base url link
        my_writef(paste0("**API cURL url: **", px[i], " {jpeg, pdf, svg}"), fo)
        next
      }
      if (grepl(hyphen_sep, px[i]) & !any(grepl('[a-zA-Z0-9]', px[i]))) {
        #hlinex()
        next
      }
      if (grepl(table_sep, px[i])) { ## table end, add separator 
        my_writef(px[i], fo)  
        hlinex()
        next
      }
      if (grepl(file_pre, px[i])) { ## file input in formdata 
        if (curl_flag) {
          my_writef(gsub(file_pre, '@Your_File_Path', px[i]), fo)  
          next
        }
      }
      cntx <- ifelse(ex_count<10, paste0("0", ex_count), paste0(ex_count))
      
      if (grepl(body_keyword, px[i])) { 
        hlinex()
        my_writef(paste0(gsub("#### ", "## ", px[i]), "   "), fo)  
        hlinex()
        next
      } 
      if (grepl(section_sep, px[i])) { 
        if (curl_flag) {
          ## Add Response Figure
          hlinex()
          my_writef("## Response   ", fo)
          newlinex()
          my_writef(paste0('![', fig_cap[ex_count], '](', 
                           paste0(fig_dir, fig_pre, cntx, fig_suffx, '.png)')), fo)
          newlinex()
          hlinex()
          
          ex_count <- ex_count + 1L
          cntx <- ifelse(ex_count<10, paste0("0", ex_count), paste0(ex_count))
          curl_flag <- FALSE
        }
        
        newlinex()
        my_writef(paste0("# Open ",toupper(section_anchor),".", cntx, 
                         " {.tabset .tabset-fade .tabset-pills}   "), fo)
        hlinex()
        my_writef(paste0('## ', section_keyword), fo)
        hlinex()
        my_writef(gsub("_\\s", "_", paste0(gsub("</span>", "", gsub(section_sep, 
                    paste0('<a name="', section_anchor, cntx,'">keyword: </a> _'), px[i])), #italic keyword
                  '_')), fo)
        next
      }
      
      if (grepl(ex_pre, px[i])) {
        my_writef("## cURL    ", fo)
        newlinex()
        my_writef(gsub(ex_pre, 
                       paste0('<a name="', ex_anchor, 
                              ifelse(ex_count<10, paste0("0", ex_count), paste0(ex_count)),
                              '">', ex_pre, ': </a>'), px[i]),
                  fo)
        #ex_count <- ex_count + 1L
        curl_flag <- TRUE
        next
      }
      
      my_writef(paste0(px[i],"   "), fo)  
    }
  }
  
  ## Add Response Figure
  if (curl_flag) {
    cntx <- ifelse(ex_count<10, paste0("0", ex_count), paste0(ex_count))
    newlinex()
    hlinex()
    
    my_writef("## Response   ", fo)
    newlinex()
    my_writef(paste0('![', fig_cap[ex_count], '](', 
                     paste0(fig_dir, fig_pre, cntx, fig_suffx, '.', fig_type, ')')), fo)
    hlinex()
    ex_count <- ex_count + 1L
    cntx <- ifelse(ex_count<10, paste0("0", ex_count), paste0(ex_count))
    curl_flag <- FALSE
  }
}

