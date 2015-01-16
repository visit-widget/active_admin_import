require 'spec_helper'

describe 'import', type: :feature do
  let(:options) { {} }

  before do
    add_author_resource(options)
    visit '/admin/authors/import'
  end

  def with_zipped_csv(name, &block)

    zip_file = File.expand_path("./spec/fixtures/files/#{name}.zip")

    begin
      Zip::File.open(zip_file, Zip::File::CREATE) do |z|
        z.add "#{name}.csv", File.expand_path("./spec/fixtures/files/#{name}.csv")
      end
      instance_eval &block
    ensure
      File.delete zip_file rescue nil
    end

  end

  def upload_file!(name, ext='csv')
    attach_file('active_admin_import_model_file', File.expand_path("./spec/fixtures/files/#{name}.#{ext}"))
    find_button('Import').click
  end


  it "has valid form" do
    form = find('#new_active_admin_import_model')
    expect(form['action']).to eq("/admin/authors/do_import")
    expect(form['enctype']).to eq("multipart/form-data")
    file_input = form.find("input#active_admin_import_model_file")
    expect(file_input[:type]).to eq("file")
    expect(file_input.value).to be_blank
    submit_input = form.find("#active_admin_import_model_submit_action input")
    expect(submit_input[:value]).to eq("Import")
    expect(submit_input[:type]).to eq("submit")
  end

  context "with hint defined" do
    let(:options){
      {template_object: ActiveAdminImport::Model.new( hint: "hint") }
    }
    it "renders hint at upload page" do
      expect(page).to have_content options[:template_object].hint
    end

  end


  context "import file" do

    [:empty, :only_headers].each do |file|
      context "when #{file} file" do
        it "should render warning" do

          upload_file!(file)
          expect(page).to have_content I18n.t('active_admin_import.file_empty_error')
          expect(Author.count).to eq(0)
        end
      end
    end

    context "when no file" do
      it "should render error" do
        find_button('Import').click
        expect(Author.count).to eq(0)
        expect(page).to have_content I18n.t('active_admin_import.no_file_error')
      end
    end

    context "with headers" do

      it "should import file with many records" do
        upload_file!(:authors)
        expect(page).to have_content "Successfully imported 2 authors"
        expect(Author.count).to eq(2)
      end

      it "should import file with 1 record" do
        upload_file!(:author)
        expect(page).to have_content "Successfully imported 1 author"
        expect(Author.count).to eq(1)
      end
    end


    context "without headers" do
      context "with known csv headers" do
        before do
          allow_any_instance_of(ActiveAdminImport::Model).to receive(:csv_headers).and_return(['Name', 'Last name', 'Birthday'])
        end

        it "should import file" do
          upload_file!(:authors_no_headers)
          expect(page).to have_content "Successfully imported 2 authors"
          expect(Author.count).to eq(2)
        end
      end

      context "with unknown csv headers" do
        it "should render error" do
          upload_file!(:authors_no_headers)
          expect(page).to have_content "Error:"
          expect(Author.count).to eq(0)
        end
      end

    end


    context "when zipped" do
      it "should import file" do
        with_zipped_csv(:authors) do
          upload_file!(:authors, :zip)
          expect(page).to have_content "Successfully imported 2 authors"
          expect(Author.count).to eq(2)
        end
      end
    end


  end


end