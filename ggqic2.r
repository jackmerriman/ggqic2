# Converts a qicharts2 object into a ggplot object
ggqic2 <- function(qiplot, use.plotly = FALSE, xlab = "X", ylab = "Y", p = FALSE,
  rules = c("outer", "stable", "trend", "shift", "sigma"),
  shift.rule = 8, trend.rule = 6, stable.rule = 15, show.nearcentre = TRUE,
  show.nearcl = TRUE, show.u95 = TRUE, show.l95 = TRUE, y.neg = TRUE) {
  library(qicharts2)
  library(tidyverse)
  if(use.plotly){library(plotly)}
  # Convert qicharts2 data into a frame ready for ggplot
  data <- qiplot$data %>%
    # For each y value given x...
    # ...Calculate if the point is over the centre-line
    mutate(overline = y>cl) %>%
    # ...Find if there are 8 consecutive points over the centre-line
    mutate(shiftgrp = cumsum(c(TRUE,diff(overline)) != 0)) %>%
    group_by(shiftgrp) %>%
    mutate(shift.signal = n()>=shift.rule) %>%
    ungroup() %>%
    # ...Find if there are 6 consecutive ascending or descending points
    mutate(diff = y-lag(y)) %>%
    mutate(ascending = diff>0) %>%
    mutate(ascending = ifelse(is.na(ascending), !lead(ascending), ascending)) %>%
    mutate(trendgrp = cumsum(c(TRUE,diff(ascending)) != 0)) %>%
    group_by(trendgrp) %>%
    mutate(trend.signal = n()>=trend.rule) %>%
    ungroup() %>%
    # ...Evaluate if the point is near the confidence levels
    mutate(nearucl = y<ucl & y>ucl.95) %>%
    mutate(nearlcl = y>lcl & y<lcl.95) %>%
    # ...Find if 2 in 3 points are near the confidence levels
    mutate(uclgrp = nearucl+
      lag(nearucl,n=2L,default = FALSE)+
      lag(nearucl,default = FALSE) +
      lead(nearucl,n=2L,default = FALSE) +
      lead(nearucl,default = FALSE)
    ) %>%
    mutate(lclgrp = nearlcl+
      lag(nearlcl,n=2L,default = FALSE)+
      lag(nearlcl,default = FALSE) +
      lead(nearlcl,n=2L,default = FALSE) +
      lead(nearlcl,default = FALSE)
    ) %>%
    mutate(outer.signal = ifelse(uclgrp >= 2 | lclgrp >= 2, TRUE, FALSE)) %>%
    # ...Calculate a near centre value in each direction
    mutate(ucentre = cl+(ucl - ucl.95)) %>%
    mutate(lcentre = cl-(ucl - ucl.95)) %>%
    # ...Find if 15 consecutive points are near the centre line
    mutate(nearcentre = y<ucentre & y>lcentre) %>%
    mutate(centregrp = cumsum(c(TRUE,diff(nearcentre)) != 0)) %>%
    group_by(centregrp) %>%
    mutate(stable.signal = n()>=stable.rule) %>%
    mutate(stable.signal = ifelse(!nearcentre, FALSE, stable.signal)) %>%
    ungroup() %>%
    # Assign special cause rules to each point
    mutate(SpecialCause = case_when(
      outer.signal == TRUE & "outer" %in% rules ~ "Edge of Control Limit",
      stable.signal == TRUE & "stable" %in% rules ~ "Stability",
      trend.signal == TRUE & "trend" %in% rules ~ "Trend",
      shift.signal == TRUE & "shift" %in% rules ~ "Shift",
      sigma.signal == TRUE & "sigma" %in% rules ~ "Outside Control Limit",
      .default = "None"
    ),
    # Create special cause factor
    SpecialCause = factor(
      SpecialCause,
      level = c("None",
        "Outside Control Limit",
        "Shift",
        "Trend",
        "Edge of Control Limit",
        "Stability"),
      ordered=FALSE
    )) %>%
    # Evaluate if each point is special cause
    mutate(SpecialCauseBool = case_when(
      SpecialCause != "None" ~ TRUE,
      SpecialCause == "None" ~ FALSE
  ))

  #Tooltip text for plotly conversion
  data$tooltipText <- str_glue("{ylab}: {round(data$y, 1)}\nUCL: {round(data$ucl,1)}  LCL: {round(data$lcl,1)}")

  #Create the plot object
  plt <- ggplot(data,aes(x,y)) +
    # Grey common cause area
    geom_ribbon(aes(ymin = lcl, ymax = ucl), fill = "grey", alpha = 0.4) +
    geom_line(colour = "cornflowerblue", linewidth = .75) + 
    # Centre line
    geom_line(aes(x,cl))
  
  # Dashes lines near confidence levels
  if (show.nearcl == TRUE) {
    if (show.u95) {plt <- plt + geom_line(aes(x,ucl.95), linetype="dashed", alpha = 0.3)}
    if (show.l95) {plt <- plt + geom_line(aes(x,lcl.95), linetype="dashed", alpha = 0.3)}
  }

  # Dotted lines near centre
  if (show.nearcentre == TRUE) {
    plt <- plt + geom_line(aes(x,ucentre), linetype="dotted", alpha = 0.2) +
    geom_line(aes(x,lcentre), linetype="dotted", alpha = 0.2)
  }

  plt <- plt +
    # Plot the points with special cause colours
    geom_point(aes(colour = SpecialCause , fill = SpecialCause, text = tooltipText, size = SpecialCauseBool)) +
    scale_fill_manual(values= c("cornflowerblue", "darkorange", "chartreuse4",
    "darkorchid1", "lightsalmon", "burlywood3"), drop = FALSE) +
    scale_colour_manual(values= c("cornflowerblue", "darkorange", "chartreuse4",
    "darkorchid1", "lightsalmon", "burlywood3"), drop = FALSE) +
    # Make special cause points bigger
    scale_size_manual(values=c(2,3)) +
    labs(x = xlab, y = ylab) +
    # Remove legend
    guides(fill="none", colour="none", size="none") +
    theme_minimal()
  # Add % to y axis if P chart
  if (p == TRUE) {
    plt <- plt + scale_y_continuous(labels = scales::percent)
  }
  # Return ggplotly if specified by user
  if(use.plotly) {
    return(ggplotly(plt, tooltip = c("text", "fill")) %>%
      config(displayModeBar = FALSE))
  } else { return(plt) }
}