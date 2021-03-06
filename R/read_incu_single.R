read_incu_single <- function(file, delay, per_image,decimal=",") {

  meta <- read_delim(file, n_max = 6, delim = ": ", col_types = "cc",
                     col_names = c("key", "value"), trim_ws = T, na = "") %>%
                     { setNames(.$value, .$key) } %>%
    as.list %>%
    as_data_frame %>%
    setNames(make.names(names(.)) %>% str_replace_all("\\.", "_"))

  result <- read_tsv(file, skip = 7, locale = locale(decimal_mark = decimal)) %>%
    setNames(gsub(": ", "", names(.)) %>% gsub(" ", "_", .)) %>%
    gather(Well, Value, -Date_Time, -Elapsed) %>%
    mutate(Elapsed = Elapsed + delay)

  if (per_image) {

    result <- result %>%
      mutate(Well = str_replace_all(Well, "_Image_", "")) %>%
      separate(Well, into = c("WellY", "WellX"), sep = 1, remove = F) %>%
      separate(WellX, into = c("WellX", "img"), sep = ",") %>%
      mutate(Well = paste0(WellY, WellX),
             WellX = as.numeric(WellX),
             img = as.numeric(img))

  } else {

    result <- separate(result, Well, into = c("WellY", "WellX"), sep = 1, remove = F) %>%
      mutate(WellX = as.numeric(WellX))

  }

  result <- list(result, meta) %>% unlist(recursive = F) %>% do.call(data_frame, .) %>%
    rename(Description = Metric) %>%
    left_join(metrics, by = "Description")

  if (any(result$Value > 100, na.rm=TRUE)) {
    stop(paste0("Wrong decimal value for ", file, " (unbound Values detected)"))
  }

  return(result)

}
