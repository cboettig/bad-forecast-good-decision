
Revision reply letters are encrypted on this repository. The reply
letter quotes the recommendations of the editors and reviewers, to which
those individuals hold copyright unless they grant express permission to
reproduce their comments here. Encrypting the reply letter preserves
this confidential correspondence in this otherwise-public repository.
The source `.Rmd` and resulting `.pdf` reply letter are then
`gitignore`’d. 

A template .Rmd of the reply letter, capturing my formatting settings,
is included here.

Encrypt to my public key:

``` r
library(gpg)
```

    ## Found GPG 2.2.19. Using keyring: /home/rstudio/.gnupg

``` r
gpg::gpg_recv("3908E1CFD28B380C") # import, needed only once
```

    ## Searching: https://keyserver.ubuntu.com

    ##      found   imported    secrets signatures    revoked 
    ##          1          0          0          0          0

``` r
msg <- gpg_encrypt("review-reply-round2.Rmd", receiver =  "3908E1CFD28B380C")
writeLines(msg, "review-reply-round2.Rmd.gpg")
```

## decrypt

(decrypt locally offline where my private key is available from yubikey,
`gpg -d review-reply.Rmd.gpg`)
