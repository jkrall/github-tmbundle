# Copyright 2008 Chris Wanstrath
# Taken from defunkt's gist repository: http://github.com/defunkt/gist/tree/master

require 'open-uri'
require 'net/http'

module Gist
  extend self

  @@gist_url = 'http://gist.github.com/%s.txt'
  @@files = []

  def read(gist_id)
    return help if gist_id == '-h' || gist_id.nil? || gist_id[/help/]
    open(@@gist_url % gist_id).read
  end
  
  def add_file(name, content)
    load_files
    @@files << {:name => name, :content => content}
    puts "#{name} added."
    save_files
  end
  
  def send(private_gist)
    load_files
    url = URI.parse('http://gist.github.com/gists')
    req = Net::HTTP.post_form(url, data(private_gist))
    url = copy req['Location']
    puts "Created gist at #{url}. URL copied to clipboard."
    clear
  end
  
  def clear
    @@files = []
    save_files
  end
  
  def process_selection
    selection = nil
    gistname = nil
    if ENV['TM_SELECTED_TEXT']
      selection = ENV['TM_SELECTED_TEXT']
      gistname = "snippet" << "." << get_extension
    else
      selection = STDIN.read
      gistname = ENV['TM_FILEPATH'] ? ENV['TM_FILEPATH'].sub(ENV['TM_PROJECT_DIRECTORY'], '') : "file" << "." << get_extension
    end
    
    add_file(gistname, selection)
  end
  
  # Add extension for supported modes based on TM_SCOPE
  # Cribbed from http://github.com/defunkt/gist.el/tree/master/gist.el
  def get_extension
    scope = ENV["TM_SCOPE"].split[0]
    case scope
    when /source\.actionscript/ : "as"
    when /source\.c/, "source.objc" : "c"
    when /source\.c\+\+/, "source.objc++" : "cpp"
    # common-lisp-mode : "el"
    when /source\.css/ : "css"
    when /source\.diff/, "meta.diff.range" : "diff"
    # emacs-lisp-mode : "el"
    when /source\.erlang/ : "erl"
    when /source\.haskell/, "text.tex.latex.haskel" : "hs"
    when /text\.html/ : "html"
    when /source\.io/ : "io"
    when /source\.java/ : "java"
    when /source\.js/ : "js"
    # jde-mode : "java"
    # js2-mode : "js"
    when /source\.lua/ : "lua"
    when /source\.ocaml/ : "ml"
    when /source\.objc/, "source.objc++" : "m"
    when /source\.perl/ : "pl"
    when /source\.php/ : "php"
    when /source\.python/ : "sc"
    when /source\.ruby/ : "rb" # Emacs bundle uses rbx
    when /text\.plain/ : "txt"
    when /source\.sql/ : "sql"
    when /source\.scheme/ : "scm"
    when /source\.smalltalk/ : "st"
    when /source\.shell/ : "sh"
    when /source\.tcl/, "text.html.tcl" : "tcl"
    when /source\.lex/ : "tex"
    when /text\.xml/, /text.xml.xsl/, /source.plist/, /text.xml.plist/ : "xml"
    else "txt"
    end
  end

private
  def load_files
    path = File.join(File.dirname(__FILE__), 'tmp_gists')
    save_files unless File.exists?(path)
    @@files = Marshal.load(File.read(path))
    @@files ||= []
  end
  
  def save_files
    path = File.join(File.dirname(__FILE__), 'tmp_gists')
    File.open(path, 'w') {|f| f.puts Marshal.dump(@@files) }
  end
  
  def copy(content)
    return content if `which pbcopy`.strip == ''
    IO.popen('pbcopy', 'r+') { |clip| clip.puts content }
  	content
  end

  def data(private_gist)
    params = {}
    @@files.each_with_index do |file, i|
      params.merge!({
        "file_ext[gistfile#{i+1}]"      => nil,
        "file_name[gistfile#{i+1}]"     => file[:name],
        "file_contents[gistfile#{i+1}]" => file[:content]
      })
    end
    params.merge(private_gist ? { 'private' => 'on' } : {}).merge(auth)
  end

  def auth
    user  = `git config --global github.user`.strip
    token = `git config --global github.token`.strip

    user.empty? ? {} : { :login => user, :token => token }
  end
end

