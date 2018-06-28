
require 'squib'
puts Squib::VERSION

require 'open-uri'

# Make sure your Google Sheet is set to "Anyone with the link can view".
# Do this by clicking the blue Share button in the upper-right hand corner,
# then clicking "Get shareable link". You can get the Google Sheet ID
# from this link, or from the URL of the sheet itself. Put it into
# the variable below.
google_sheet_id = "1rOYZ0d7_SxZd8rwhxzNQ7za6Yxq8w9Klqy_REITlhUI"
# Each subsheet within a Google sheet has a unique ID in its URL called the gid.
sheet_gid = "0"

buffer = open("https://docs.google.com/spreadsheets/d/#{google_sheet_id}/export?format=csv&gid=#{sheet_gid}").read
File.open("cards.csv", 'wb') do |file|
    file << buffer
end

cardWidth = 1500
cardHeight = 2100
dpi = 600

# Outputs a hash of arrays with the header names as keys
data = Squib.csv file: 'cards.csv', explode: 'Quantity'

numCards = data['Name'].length

if numCards <= 0
    puts "No cards found in Google Sheet."
    exit
end

layouts = [ 'global_layout.yml', 'program_layout.yml', 'operation_layout.yml',
            'asset_layout.yml', 'event_layout.yml', 'upgrade_layout.yml', 'hardware_layout.yml',
            'resource_layout.yml', 'ice_layout.yml', 'agenda_layout.yml', 'runnerid_layout.yml',
            'corpid_layout.yml' ]
Squib::Deck.new(cards: numCards, width: cardWidth, height: cardHeight, dpi: dpi, layout: layouts) do
    background color: '#ffffff00'

    # Artwork
    def clean_artwork_name(name)
        name = name.gsub(/[ ]/, '_')
        # Remove the (U) special character.
        name = name.gsub(/(\(.\))/, '')
        name = name.gsub(/[^0-9A-Za-z_]/, '')
        name = name.downcase
        return name
    end
    artwork = data['Name'].map { |name| 'art/' + clean_artwork_name(name) + '.png' }
    artworkValid = artwork.map { |name| name unless !Pathname.new(name).exist? }

    def get_layouts(name, data)
        return data['Type'].map { |type| type + '_' + name }
    end

    png layout: get_layouts('artwork', data), file: artworkValid

    # Card template
    templateLayouts = []
    data['Type'].each { |type| templateLayouts.push('card_template_' + type + '_') }
    data['Faction'].each_with_index { |faction, index| templateLayouts[index] += faction }
    png layout: templateLayouts

    # Line around card for cutting
    rect layout: 'cut_line'

    # Card name
    text layout: get_layouts('name_text', data), str: data['Name']

    # Runner Identity Subname
    text layout: 'subname_text', str: data['Subname']

    # Corp Identity Slogan
    text layout: 'slogan_text', str: data['Slogan']

    # Cost
    text layout: get_layouts('cost_text', data), str: data['Cost']

    # MU
    text layout: 'mu_text', str: data['MU']

    # Points
    text layout: 'points_text', str: data['Points']

    # Strength
    text layout: get_layouts('strength_text', data), str: data['Strength']

    # Influence
    text layout: get_layouts('influence_text', data), str: data['Influence']

    # Subtypes
    text layout: get_layouts('subtypes_text', data), str: data['Subtypes']

    # Trash cost
    text layout: get_layouts('trash_text', data), str: data['Trash']

    # Ability text
    text layout: get_layouts('ability_text', data), str: data['Ability']

    # Flavor text
    text layout: get_layouts('flavor_text', data), str: data['Flavor']

    # Illustration credits text
    illusText = data["Illus"].map { | illus | "Illus. " + (illus.nil? ? "Nobody" : illus) }
    text layout: get_layouts('illus_text', data), str: illusText

    save_pdf file: 'cards.pdf', width: 11 * dpi, height: 8.5 * dpi,
             margin: dpi * 0.45, gap: 1, trim: 0, crop_marks: true
end
