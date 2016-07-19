require 'rails_helper'

feature 'IdV session' do
  let(:mock_questions) { Proofer::Vendor::Mock.new.build_question_set(nil) }

  scenario 'KBV with all answers correct' do
    user = sign_in_and_2fa_user

    visit '/idv/sessions'

    expect(page).to have_content(t('idv.form.first_name'))

    fill_in :first_name, with: 'Some'
    fill_in :last_name, with: 'One'
    fill_in :ssn, with: '666661234'
    fill_in :dob, with: '19800102'
    fill_in :address1, with: '123 Main St'
    fill_in :city, with: 'Nowhere'
    select 'Kansas', from: :state
    fill_in :zipcode, with: '66044'
    click_button 'Continue'

    expect(page).to have_content('Where did you live')

    %w(city bear quest color speed).each do |answer_key|
      question = mock_questions.find_by_key(answer_key)
      answer_text = Proofer::Vendor::Mock::ANSWERS[answer_key]
      if question.choices.nil?
        fill_in :answer, with: answer_text
      else
        choice = question.choices.detect { |c| c.key == answer_text }
        el_id = "#choice_#{choice.key_html_safe}"
        find(el_id).set(true)
      end
      click_button 'Next'
    end

    expect(page).to have_content(t('idv.titles.complete'))

    expect(user.active_profile).to be_a(Profile)
    expect(user.active_profile.verified?).to eq true
    expect(user.active_profile.ssn).to eq '666661234'
  end

  scenario 'KBV with some incorrect answers' do
    sign_in_and_2fa_user

    visit '/idv/sessions'

    expect(page).to have_content(t('idv.form.first_name'))

    fill_in :first_name, with: 'Some'
    fill_in :last_name, with: 'One'
    fill_in :ssn, with: '666661234'
    fill_in :dob, with: '19800102'
    fill_in :address1, with: '123 Main St'
    fill_in :city, with: 'Nowhere'
    select 'Kansas', from: :state
    fill_in :zipcode, with: '66044'
    click_button 'Continue'

    expect(page).to have_content('Where did you live')

    %w(city bear quest color speed).each do |answer_key|
      question = mock_questions.find_by_key(answer_key)
      answer_text = Proofer::Vendor::Mock::ANSWERS[answer_key]
      if question.choices.nil?
        fill_in :answer, with: 'wrong'
      else
        choice = question.choices.detect { |c| c.key == answer_text }
        el_id = "#choice_#{choice.key_html_safe}"
        find(el_id).set(true)
      end
      click_button 'Next'
    end

    expect(page).to have_content(t('idv.titles.hardfail'))
  end

  scenario 'un-resolvable PII' do
    sign_in_and_2fa_user

    visit '/idv/sessions'

    expect(page).to have_content(t('idv.form.first_name'))

    fill_in :first_name, with: 'Bad'
    fill_in :last_name, with: 'User'
    fill_in :ssn, with: '6666'
    fill_in :dob, with: '19000102'
    fill_in :address1, with: '123 Main St'
    fill_in :city, with: 'Nowhere'
    select 'Kansas', from: :state
    fill_in :zipcode, with: '66044'
    click_button 'Continue'

    expect(page).to have_content(t('idv.titles.fail'))
  end
end
