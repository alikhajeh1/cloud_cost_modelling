module ApplicationHelper

  def title(page_title)
    content_for(:title, page_title.to_s)
  end

  def header(header, page_title=nil, help='')
    page_title = header unless page_title
    title(page_title)
    html = "<div class='row'><div class='span10'><h2>".html_safe
    html << header.to_s
    html << "</h2></div><div class='span2 offset4' style='padding-top:10px; text-align:right'><span class='label warning dropdown-toggle' id='help_button' style='cursor:pointer'>Help</span></div></div></div>".html_safe
    html << "<div class='alert-message block-message warning' id='help' style='display:none'>".html_safe
    html << help.html_safe
    html << "</div><br/>".html_safe
    content_for(:header, html)
  end

  def editable_header(header_object, help='')
    if header_object.has_attribute?(:name)
      title(header_object.name)
      html = "<div class='row'><div class='span14'><h2>".html_safe
      html << "#{header_object.class.to_s.underscore.humanize} - "
      html << (best_in_place header_object, :name)
      html << " <small>#{(best_in_place header_object, :description, :type => :textarea, :nil => 'Click to add a description')}</small>".html_safe if header_object.has_attribute?(:description)
      html << "</h2></div><div class='span2' style='padding-top:10px; text-align:right'><span class='label warning dropdown-toggle' id='help_button' style='cursor:pointer'>Help</span></div></div></div>".html_safe
    end
    html << "<div class='alert-message block-message warning' id='help' style='display:none'>".html_safe
    html << help.html_safe
    html << "</div><br/>".html_safe
    content_for(:header, html)
  end

  def jq_button(title, icon, icon_corner, link_object, options={})
    corner_class = "ui-corner-#{icon_corner}" if icon_corner
    link_to raw("<span class='ui-button-icon-primary ui-icon ui-icon-#{icon}'></span><span class='ui-button-text'>#{title}</span>"), link_object,
            {:class => "ui-button ui-button-icon-only ui-widget ui-state-default #{corner_class}", :title => title, :rel => 'twipsy'}.merge(options)
  end

  def pattern_button(patterns_hash)
    "<span class='label success dropdown-toggle pattern_button'>#{patterns_hash[:selected_patterns_count]} Patterns</span>".html_safe
  end

  def report_button(button_name)
    "<span class='label success dropdown-toggle report_button'>#{button_name}</span>".html_safe
  end
end