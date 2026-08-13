//
//  StringConstants.swift
//  MobileERP
//
//  Created by Nikesh Jha on 10/12/15.
//  Copyright (c) 2015 Sunil Luitel. All rights reserved.
//

import Foundation

open class StringConstants{
    static let YLWDateKb_KeyList = [["1","2","3",sdkLocalizedString("First day", comment: "First day"),sdkLocalizedString("Last day", comment: "Last day")],["4","5","6","Year","Month"],["7","8","9","Day","←"],[sdkLocalizedString("increase", comment: "increase"),sdkLocalizedString("decrease", comment: "decrease"),"0",sdkLocalizedString("Date", comment: "Date"),sdkLocalizedString("Today", comment: "Today"),sdkLocalizedString("Enter", comment: "Enter")]]
    
//    static let YLWNumberkb_KeyList = [["7","8","9","*","/"], ["4","5","6","+","-"], ["1","2","3","=","←"], ["00","0",".","Enter"]]
    
    static let YLWNumberkb_KeyList = [["1","2","3","*","/"], ["4","5","6","+","-"], ["7","8","9","=","←"], ["00","0",".",sdkLocalizedString("Enter", comment: "Enter")]]
    
    static let YLWYyyyMMDateKb_KeyList = [["1","4","7","10"], ["2","5","8","11"], ["3","6","9","12"], [sdkLocalizedString("Year", comment: "Year"),sdkLocalizedString("Year", comment: "Year"),sdkLocalizedString("Enter", comment: "Enter")]]
    
    static let error = sdkLocalizedString("Error", comment: "Error")
    static let success = sdkLocalizedString("Success", comment: "Success")
    static let Edit = sdkLocalizedString("Edit", comment: "Edit")
    
    static let Sheet_Settings = sdkLocalizedString("Sheet Settings", comment: "Sheet Settings")
    
    static let Column_Name = sdkLocalizedString("Column Name", comment: "Column Name")
    
    static let Fixed = sdkLocalizedString("Fixed", comment: "Fixed")
    
    static let Hidden = sdkLocalizedString("Hidden", comment: "Hidden")
    
    static let Sheet_Fix_limit = sdkLocalizedString("Sheet Fix limit", comment: "Only 3 columns can be fixed")
    
    static let copy = sdkLocalizedString("Copy", comment: "Copy")
    static let paste = sdkLocalizedString("Paste", comment: "Paste")
    static let delete = sdkLocalizedString("Delete", comment: "Delete")
    static let cancel = sdkLocalizedString("Cancel", comment: "Cancel")
    static let controls_not_Registered = sdkLocalizedString("Controls not Registered", comment: "Controls not Registered")
    static let wait_text = sdkLocalizedString("Wait text", comment: "Please Wait...")
    static let noCaptureData = sdkLocalizedString("NoCaptureData", comment: "There is no Captured Data.")
    static let input_mode_event_cancel = sdkLocalizedString("Input mode event cancel", comment: "Cannot execute this event on input mode")
    static let pgm_loaded = sdkLocalizedString("Pgm loaded", comment: "Program Already Loaded")
    static let pls_select_text = sdkLocalizedString("Pls select text", comment: "There's no selected item. \n Please, select item on <b>SelectedItem</b> list") //선택된 항목이 없습니다. \n <b>보이는 항목</b>에서 선택하세요.
    
    static let noActiveRow = sdkLocalizedString("NoActiveRow", comment: "There is no active row.")
    static let noCheckedRow = sdkLocalizedString("NoCheckedRow", comment: "There is no checked row.")
    static let noSelectedRow = sdkLocalizedString("NoSelectedRow", comment: "There is no selected row.")
    static let noDblClickedRow = sdkLocalizedString("NoDblClickedRow", comment: "There is no double clicked row.")
    
    static let svc_err = sdkLocalizedString("Svc err", comment: "Service error")
    static let time_out = sdkLocalizedString("Time out", comment: "Time-out")
    static let time_out_retry = sdkLocalizedString("Time out retry", comment: "Time-out! Try again?")
    static let data_capture_success = sdkLocalizedString("Data capture success", comment: "Data captured successfully")
    static let data_limit_title = sdkLocalizedString("Data limit title", comment: "Too many Queried data")
    static let data_limit_message_1 = sdkLocalizedString("Data limit message 1", comment: "Total ")
    static let data_limit_message_2 = sdkLocalizedString("Data limit message 2", comment: "s of data is queried. But, due to size, only ")
    static let data_limit_message_3 = sdkLocalizedString("Data limit message 3", comment: "s of data is received. \nPlease change the query conditionn to receive adaptable size of data.")
    static let data_limit_message = sdkLocalizedString("Data limit message", comment: " [Warning] too much data is queried. \n Please change the query condition to receive adaptable size of data. \n ")
    static let camera_not_supported = "The camera is not supported."
    
    static let NoJumpDataBlock = "No Progress Jump DataBlock"
    static let NoProgressService = "No Seq for Progress Service"
    static let noDataSet = "No DataSet"
    static let invalid_entry = "Invalid Entry"
    static let clear_confirm = "Do you want to clear all text?"
    static let notExistRow = "no data reflect"
    static let NotProperProgressService = "Not proper Progress Service"
    static let NoDataToJump = sdkLocalizedString("NoDataToJump", comment: "No Data to jump!")
     static let noQueryData = sdkLocalizedString("noQueryData", comment: " There is no queried item ")
    
    static let sheetSettingFixedColumnsIssue = sdkLocalizedString("sheetSettingFixedColumnsIssue", comment: " Too many records are there in grid, creating fixed columns will cause instability to the sheet functionality ")

    static let multiCombo_selectedValueConfirm =  sdkLocalizedString("multiCombo_selectedValueConfirm", comment: "Do you want to apply the selected values?")
    static let multiCodehelp_resetValuesConfirm = sdkLocalizedString("multiCodehelp_resetValuesConfirm", comment: "Prompt dialog asking user to reset all the selected values for current codehelp component")
    
    
    //       <!-- chart setting -->
    static let Chart_select_hint = "Select Chart Type"
    static let Chart_select_date = "Select the basic date"
    static let Chart_select_quantity = "Select quantity column"
    static let Chart_select_group = "Select item group"
    static let sheet = "Sheet"
    static let barChart = "Bar Chart"
    static let lineChart = "Line Chart"
    static let pieChart = "Pie Chart"
    static let areaChart = "Area Chart"
    static let bubbleChart = "Bubble chart"
    static let chooseAxis = "Choose axis"
    static let etcHeader = "Etc Content"

    
    //line chart
    static let chooseDate = "Choose Date"
    
    // bar chart
    static let multiplebarchart_default_title = "Index Values"
    
    
    /** osbaek added **/
    
    static let YLWDateKbCtrlSetting_KeyList = [[sdkLocalizedString("Before 1 year", comment: "Before 1 year"),sdkLocalizedString("Before 1 month", comment: "Before 1 month"),sdkLocalizedString("Before 1 week", comment: "Before 1 week"),sdkLocalizedString("Before 1 day", comment: "Before 1 day")], [sdkLocalizedString("After 1 year", comment: "After 1 year"),sdkLocalizedString("After 1 month", comment: "After 1 month"),sdkLocalizedString("After 1 week", comment: "After 1 week"),sdkLocalizedString("After 1 day", comment: "After 1 day")], [sdkLocalizedString("First Month", comment: "First Month"),sdkLocalizedString("First day", comment: "First day"),sdkLocalizedString("The very date", comment: "The very date"),sdkLocalizedString("date dialog", comment: "date dialog")], [sdkLocalizedString("Last month", comment: "Last month"),sdkLocalizedString("Last day", comment: "Last day"),"Back step","Enter"]]
    
    static let Control_Settings = sdkLocalizedString("Control Settings", comment: "Control Settings")
    static let Control_Settings_Hidden = sdkLocalizedString("Control Settings Hidden", comment: "Control Settings Hidden")
    static let Control_Settings_ColName = sdkLocalizedString("Control Settings ColName", comment: "Control Settings ColumnName")
    static let Control_Settings_DefValue = sdkLocalizedString("Control Settings DefValue", comment: "Control Settings Default Value")
    static let Setting = sdkLocalizedString("Setting", comment: "Setting")
    static let Done = sdkLocalizedString("Done", comment: "Done")

    
    //Sunil Added for Demo
    static let painList = sdkLocalizedString("ERP Pain", comment: "ERP Pain")
    static let moduleList = sdkLocalizedString("Modules", comment: "Modules")
    static let guide = sdkLocalizedString("Guide", comment: "Guide")
    static let noscenario = "There is no Scenario data"
    static let nostep = "There is no Step data"
    static let unsuccessful = sdkLocalizedString("Unsuccessful", comment: "Unsuccessful")
    static let noStep = "There is no Step Data"
    static let noScenario = "There is no scenario Data"
    static let experience = sdkLocalizedString("Experience", comment: "Experience")
    static let startExperience = "Start Experience"
    static let endExperience = "End Experience"
    static let demo_save_msg = sdkLocalizedString("demo_save_msg", comment: "Because it's Demo version, data can't be modified.")
    //MARK: Demo Feedback Dialog Strings
    static let demo_feedbackDialog_askingExperience = sdkLocalizedString("demo_feedbackDialog_askingExperience", comment: "How was the experience?")
    static let demo_feedbackDialog_reviewAsGood = sdkLocalizedString("demo_feedbackDialog_reviewAsGood", comment: "Good!")

    static let demo_feedbackDialog_reviewAsSoso = sdkLocalizedString("demo_feedbackDialog_reviewAsSoso", comment: "Soso!")

    static let demo_feedbackDialog_reviewAsBad = sdkLocalizedString("demo_feedbackDialog_reviewAsBad", comment: "Bad!")

    static let demo_feedbackDialog_Submit = sdkLocalizedString("demo_feedbackDialog_Submit", comment: "Submit")

    static let demo_feedbackDialog_askingDetails = sdkLocalizedString("demo_feedbackDialog_askingDetails", comment: "Want more details!")

    
    /*********************************
     Added by - OM PRAKASH -> START */
    
    //MARK: BUG REPORT FORM LABELS STRING
    static let BugReportForm_Label_FormHeading = sdkLocalizedString("Bug Report", comment: "Form Heading")
    static let BugReportForm_Label_BugDescription = sdkLocalizedString("Bug Description", comment: "Bug Description")
    static let BugReportForm_Label_Email = sdkLocalizedString("Email", comment: "Email")
    static let BugReportForm_Label_PhoneNumber = sdkLocalizedString("Phone Number", comment: "Phone Number")
    static let BugReportForm_Label_RequestCall = sdkLocalizedString("Req Call", comment: "Request Call")
    static let BugReportForm_Label_Agreement = sdkLocalizedString("Do you agree to terms?", comment: "Agreement")
    
    static let BugReportForm_Placeholder_Email = sdkLocalizedString("*Email Required", comment: "Email required")
    
    static let BugReportForm_TelephoneNote = sdkLocalizedString("This if may be for request call", comment: "Telephone Note")
    
    static let BugReportForm_ButtonTitle_Cancel = sdkLocalizedString("Cancel", comment: "Cancel bug reporting")
    static let BugReportForm_ButtonTitle_Report = sdkLocalizedString("Report", comment: "Reporting")
    
    
    
    /* by - OM PRAKASH -> END
     **********************************/
    
    //bugreportlistview
    static let bugreportlist_menutitle = sdkLocalizedString("Service Reception History", comment: "Service Reception History")
    static let bugreportlist_titletext = sdkLocalizedString("No Bug Report History ", comment: "There is no bug report history")
    static let bugreportlist_subtext = sdkLocalizedString("Register Bug Report", comment: "You can register bug report in ERP program")
    static let bug_waiting = sdkLocalizedString("ProcessStatusText_0", comment: "Waiting")
    static let bug_inprogress = sdkLocalizedString("ProcessStatusText_1", comment: "In Progress")
    static let bug_done = sdkLocalizedString("ProcessStatusText_2", comment: "Done")
    static let bug_doneImmediately = sdkLocalizedString("ProcessStatusText_3", comment: "Done-Immediately")
    static let bug_unreplicated = sdkLocalizedString("ProcessStatusText_5", comment: "Unreplicated")
    static let bug_not_supported = sdkLocalizedString("ProcessStatusText_4", comment: "Not Supported")
    static let bug_other = sdkLocalizedString("ProcessStatusText_6", comment: "Other")
    
    
    //detailbugreportview
    static let detailbugreport_title = sdkLocalizedString("BugReportDetailTitleText", comment: "Bug Report Detail")
    static let detailbugreport_editBtnText = sdkLocalizedString("BugReportUpdateText", comment: "Update")
    static let  detailbugreport_DateText = sdkLocalizedString("CompletedDateText", comment: "Completed Date")
    static let detailbugreport_versiontext = sdkLocalizedString("AppliedVersionText", comment: "Applied Version")
    static let detailbugreport_pgmNamePrePositionTxt = sdkLocalizedString("PgmNamePrePositionText", comment: "In")
    static let unsucessful =  sdkLocalizedString("Unsucessful", comment: "Unsucessful")
    static let releaseDateTitle = sdkLocalizedString("ReleaseDateTitleText", comment: "Release Date Title")
    static let releaseVersionTitle = sdkLocalizedString("ReleaseVersionTitleText", comment: "Release Version Title")
    
    //17.02.15 mobile demo
    static let demoStartButtonTitle = sdkLocalizedString("demoStartButtonTitle", comment: "Getting Started")
    
    //17.02.15 
    static let welcome = sdkLocalizedString("Welcome", comment: "Welcome")
    static let explain_start = sdkLocalizedString("explain_start", comment: "If you have an account\nTry it right away.")
    static let explain_experience = sdkLocalizedString("explain_experience", comment: "ERP, Why hesitate?\nExperience and Resolve.")
    
    static let data_changed_check_1 = sdkLocalizedString("data_changed_check_1", comment: "Content has changed. Would you like to save it?")
    static let data_changed_check_2 = sdkLocalizedString("data_changed_check_2", comment: "All input data will be lost, you still want to clear the form")
    static let alert_sheetcut = sdkLocalizedString("alert_sheetcut", comment: "Are you sure you want to delete the selected row?")
    static let alert_before_save = sdkLocalizedString("alert_before_save", comment: "Do you want to save?")
    static let alert_after_save = sdkLocalizedString("alert_after_save", comment: "It has been saved.")
    static let alert_before_delete = sdkLocalizedString("alert_before_delete", comment: "Are you sure you want to delete?")
    static let alert_after_delete = sdkLocalizedString("alert_after_delete", comment: "It has been deleted.")
    static let login_demo_txt = sdkLocalizedString("login_demo_txt", comment: "login_demo_txt_en")
    static let serverSettingChangedMsg = sdkLocalizedString("serversetting_changed", comment: "Server setting will be changed. Do you want to continue?")
    static let shareWaitMessage = sdkLocalizedString("shareWaitMessage", comment: "Preparing data for sharing, please wait")
    static let shareSuccessfulMessage = sdkLocalizedString("shareSuccessfulMessage", comment: "Program data on ERP is shared")
    static let loginText = sdkLocalizedString("Login Text", comment: "Login")
    
    

    //18.08.31
    static let apiOpenError = sdkLocalizedString("apiOpenError", comment: "This is unavailable.")
    
    //0919 change password
    static let password_check_rules_msg = sdkLocalizedString("password_check_rules_msg", comment: "Please check password rules.")
    static let password_no_respond_msg = sdkLocalizedString("password_no_respond_msg", comment: "Server not responding.")
    static let password_check_loginpassword_msg = sdkLocalizedString("password_check_loginpassword_msg", comment: "Please check your login password.")
    static let password_change_success = sdkLocalizedString("password_change_success", comment: "Your password has been changed.")
    static let password_notmatch_msg = sdkLocalizedString("password_notmatch_msg", comment: "The new password does not match.")
    static let password_encrypt_error_msg = sdkLocalizedString("password_encrypt_error_msg", comment: "The password does not encrypt.")
    
    static let confirmText = sdkLocalizedString("ConfirmText", comment: "Confirm")
    static let password_change_title = sdkLocalizedString("password_change_title", comment: "Change Password")
    static let password_prev_text = sdkLocalizedString("password_prev_text", comment: "Previous password")
    static let password_prev_input = sdkLocalizedString("password_prev_input", comment: "input previous password")
    static let password_new_text = sdkLocalizedString("password_new_text", comment: "New password")
    static let password_new_input = sdkLocalizedString("password_new_input", comment: "input new password")
    static let password_confirm_text = sdkLocalizedString("password_confirm_text", comment: "Confirm new password")
    static let password_confirm_input = sdkLocalizedString("password_confirm_input", comment: "input new password")
    static let password_rules_text = sdkLocalizedString("password_rules_text", comment: "password rules")
    static let password_expired_text = sdkLocalizedString("password_expired_text", comment: "Password is expired.")
    static let password_askchange_text = sdkLocalizedString("password_askchange_text", comment: "Password change")
    
    //Image control .
    static let image_text = sdkLocalizedString("image_text", comment: "Image")
    static let camera_text = sdkLocalizedString("camera_text", comment: "Camera")
    
    //File Input control .
    static let attached_text = sdkLocalizedString("attached_text", comment: "File text")
    static let fileUploading = sdkLocalizedString("fileUploading", comment: "File upload status")
    static let fileDownloading = sdkLocalizedString("fileDownloading", comment: "File download status")
    
    static let success_Uploading = sdkLocalizedString("Success_Uploading", comment: "Success Uploading msg")
    static let success_Downloading = sdkLocalizedString("Success_Downloading", comment: "Success Downloading msg")
    static let success_Deleting = sdkLocalizedString("Success_Deleting", comment: "Success Deleting msg")
    
    static let error_Uploading = sdkLocalizedString("Error_Uploading", comment: "Error Uploading msg")
    static let error_Downloading = sdkLocalizedString("Error_Downloading", comment: "Error Downloading msg")
    static let error_Deleting = sdkLocalizedString("Error_Deleting", comment: "Error Deleting msg")
    
    static let uploadLimit_Exceeded = sdkLocalizedString("UploadLimit_exceeded", comment: "Upload limit exceeds msg")
    static let noFileService = sdkLocalizedString("NoFileService", comment: "No File Service")
    static let noFileServerDir = sdkLocalizedString("NoFileServerDir", comment: "No File Server Directory")
    
    
    //MARK: ------------- COMPANITY MODULE -----------------
    static let PinSuccessMsg = sdkLocalizedString("PinnedMsg", comment: "Paper Pin Successful")
    
    static let archivesVCTitle = sdkLocalizedString("ArchivesVCTitle", comment: "Archive papers")
    static let hiddenVCTitle = sdkLocalizedString("HiddenVCTitle", comment: "Hidden papers")
    
    static let hidePaperSuccessMsg = sdkLocalizedString("hidePaperSuccessMsg", comment: "Paper hide Successful")
    static let unhidePaperSuccessMsg = sdkLocalizedString("unhidePaperSuccessMsg", comment: "Paper unhide successful")
    static let archivePaperSuccessMsg = sdkLocalizedString("archivePaperSuccessMsg", comment: "Paper archive Successful")
    static let deletePaperSuccessMsg = sdkLocalizedString("deletePaperSuccessMsg", comment: "Paper delete successful")
    
    static let deletePaperFailMsg = sdkLocalizedString("deletePaperFailMsg", comment: "Paper delete failed")
    static let deletePaperPermissionDeniedMsg = sdkLocalizedString("deletePaperPermissionDeniedMsg", comment: "Paper permission denied")
    
    static let writeToPlaceholder =  sdkLocalizedString("writeToPlaceholder", comment: "Name of receipent group") //"UX Design WG"
    static let descriptionPlaceholder = sdkLocalizedString("Description", comment: "Paper description")
    
    static let hashTagRegularExpression = "#(\\w+)"
    

    //FeedBackDetails
    static let All_title_text = sdkLocalizedString("All", comment: "All")
    
    static let searchResultsUnavailable = sdkLocalizedString("SearchResultsUnavailable", comment: "Results not found.")
    static let programSearchPlaceholder = sdkLocalizedString("ProgramSearchPlaceholder", comment: "Program search keyword")
    static let myMenu = sdkLocalizedString("MyMenu", comment: "My Menu Option")


    //MARK: VoteListView
    static let profileLoading = "Loading..."
    static let addVoteItem = sdkLocalizedString("AddVoteItem", comment: "Adding a vote item")
    
    static let board = sdkLocalizedString("Board", comment: "Board")
    static let companity = sdkLocalizedString("Companity", comment: "Companity")
    static let contact = sdkLocalizedString("Contact", comment: "Contact")
    static let noVoters = sdkLocalizedString("noVoters", comment: "No Voters")
    static let attendance = sdkLocalizedString("Attendance", comment: "Attendance")
    

    //MainDetailTableViewCell
    static let paper_moreBtnText = sdkLocalizedString("More", comment: "View more")
    static let voter_info_disable_msg = sdkLocalizedString("voter_info_disable_msg", comment: "Voter Information cannot be Displayed.")
    
    //SearchViewController
    static let noSearchResults = sdkLocalizedString("NoResult", comment: "There is no search results.")
    
    //PaperViewController
    static let noPapers = sdkLocalizedString("NoPapers", comment: "No papers.")
    
    //MARK: VoteHeaderView
    static let VoteHeader_DeadlineText = sdkLocalizedString("Deadline", comment: "Deadline text")
    static let VoteHeader_multiSelection = sdkLocalizedString("MultiSelection", comment: "Multiple Selection")
    static let VoteHeader_anonymousText = sdkLocalizedString("AnonymousText", comment: "Anonymous Vote")
    static let VoteHeader_hideVotersText = sdkLocalizedString("HideVotersText", comment: "Hide Voters")
    static let VoteHeader_hideCountText = sdkLocalizedString("HideCountText", comment: "Hide Count")

    //MARK: CreateVoteView
    static let no_option_item = sdkLocalizedString("NoOptions", comment: "No option items")
    static let attachment_and_no_text = sdkLocalizedString("AttachmentNoText", comment: "Attachments but no text present")
    static let deadline_error = sdkLocalizedString("DeadlineError", comment: "Deadline must be atleast 15 minutes more than current time.")
    static let select_closing_date_time = sdkLocalizedString("SelectClosinDateTime", comment: "Please select the vote closing date and time")
    static let limit = sdkLocalizedString("Limit", comment: "Limit")
    static let enterTheContent = sdkLocalizedString("enterTheContent", comment: "enterTheContent placeholder")
    static let ReceiveGroup = sdkLocalizedString("ReceiveGroup", comment: "Receive Group")
    static let limitGreaterThanZero = sdkLocalizedString("limitGreaterThanZero", comment: "Limit Greater Than Zero")
    static let limitCannotBeEmpty = sdkLocalizedString("limitCannotBeEmpty", comment: "Limit  Cannot Be Empty")
    
    static let atLeastTwoVoteOptionsRequired = sdkLocalizedString("atLeastTwoVoteOptionsRequired", comment: "AtLeast Two Vote Options Required")
    static let NoOptions = sdkLocalizedString("NoOptions", comment: "No option items")
    static let AttachmentNoText = sdkLocalizedString("AttachmentNoText", comment: "Attachments but no text present")
    
    static let DeadlineError = sdkLocalizedString("DeadlineError", comment: "Deadline must be atleast one hour more than current time.")
    
    static let SelectClosinDateTime = sdkLocalizedString("SelectClosinDateTime", comment: "Please select the vote closing date and time")
    static let and = sdkLocalizedString("and", comment: "and")
    static let other = sdkLocalizedString("other", comment: "other")
    static let others = sdkLocalizedString("others", comment: "others")
    static let andOthers = sdkLocalizedString("andOthers", comment: "and others")
    
    //VoteDatePickerView 
    static let dateAlreadySelected = sdkLocalizedString("DateSelected", comment: "Date already selected")
    static let minDateToday = sdkLocalizedString("MinDayToday", comment: "Minimum day is today")

    //Paper and Vote attachments errors
    static let urlLoadError = sdkLocalizedString("UrlLoadError", comment: "Cannot load URL!")

    //email singup and signin
    static let email_already_linked = sdkLocalizedString("EmailAlreadyLink", comment: "This email id is linked with another account")
    
    //MARK: ChooseReceiverViewController
    static let selectReceivers = sdkLocalizedString("selectReceivers", comment: "select recipients")
    static let receiverLblTxt = sdkLocalizedString("receiverLblTxt", comment: "Recepient text")
    static let receiverSearchPlaceHolderText =  sdkLocalizedString("receiverSearchPlaceHolderText", comment: " receipent group placeholder text")
    static let recentUsersTxt = sdkLocalizedString("recentUsersTxt", comment: "Recent receipients")
    static let allUsersText = sdkLocalizedString("allUsersText", comment: "All Users")
    
    //edit paper
    static let updatePaperConfirmMsg = sdkLocalizedString("updatePaperConfirmMsg", comment: "Paper update congirmation dialog")
    static let updatePaperSuccessMsg = sdkLocalizedString("updatePaperSuccessMsg", comment: "Paper update successful")
    static let updatePaperWithMissingAttach = sdkLocalizedString("updatePaperWithMissingAttach", comment: "Paper update successful with missing attachment")
    static let paperNotChangeMsg  = sdkLocalizedString("paperNotChangeMsg", comment: "No Changes made.")
    static let votePaperEditNotAllowed  = sdkLocalizedString("votePaperEditNotAllowed", comment: "cannot edit vote paper")
    static let paperEditByOwnerMsg = sdkLocalizedString("paperEditByOwnerMsg", comment: "Only sender can edit paper")
    static let editPaperTitleTxt = sdkLocalizedString("editPaperTitleTxt", comment: "edit paper title text")
    
    static let changedFingerprint = sdkLocalizedString("changedFingerprint", comment: "The fingerprint is changed on the device.")
    
    //Employee List View
    static let noEmployeeData = sdkLocalizedString("noEmployeeData", comment: "No employees found.")
    
    //PhotoChangeView
    static let org_empinfo_dialog_profilephoto = sdkLocalizedString("ProfilePhoto", comment: "Profile photo")
    static let org_empinfo_dialog_album_choice = sdkLocalizedString("AlbumPhoto", comment: "Choice photo in album.")
    static let org_empinfo_dialog_camera = sdkLocalizedString("TakePhoto", comment: "Take photo")
    static let org_empinfo_dialog_init = sdkLocalizedString("DeleteMyPhoto", comment: "Delete my photo")
    static let org_empinfo_dialog_backgroundphoto = sdkLocalizedString("BackgroundPhoto", comment: "Background photo")
    
    //Map Viewcontroller
    static let mapTitleMsg = sdkLocalizedString("mapTitleMsg", comment: "Map Title Text")
    static let mapSearchBoxPlaceHolderMsg = sdkLocalizedString("mapSearchBoxPlaceHolderMsg", comment: "Map Search Box empty text")
    static let selectLocation = sdkLocalizedString("selectLocation", comment: "Select a location")
    static let unknownLocation = sdkLocalizedString("unknownLocation", comment: "Unknown location")
    
    //ArchiveViewController
    static let unarchiveAllPaperConfirmMsg = sdkLocalizedString("unarchiveAllPaperConfirmMsg", comment: "all instance of archive paper delete message ")
    static let unarchiveConfirmMsg = sdkLocalizedString("unarchiveConfirmMsg", comment: "archive paper delete  message")
    
    //EmpProfileManageViewController
    static let  org_profile_ment = sdkLocalizedString("ProfileDefaultMsg", comment: "Please register profile message.")
    
    static let org_member_detail = sdkLocalizedString("OrgMemberDetail", comment: "Member details")
    // Path for file server
    static let companity_paperAttachments_path = "\\Companity\\PaperAttachments\\"
    static let companity_voteAttachments_path = "\\Companity\\VoteAttachments\\"
   
    
    //mainviewcontroller
    static let companyName = sdkLocalizedString("companyName", comment: "Company Name")

    //AttachmentPreviewController
    static let attachmentPreviewTitleTxt = sdkLocalizedString("attachmentPreviewTitleTxt", comment: "Title Text")

    static let paperNotiTitle = sdkLocalizedString("paperNotiTitle", comment: "Paper Notification Title")
    static let currentUser = sdkLocalizedString("currentUser", comment: "me")
    
    static let dateFormatLocalizedCompanity = sdkLocalizedString("dateFormatLocalizedCompanity", comment: "date format for companity")
    static let dateTimeFormatLocalizedCompanity = sdkLocalizedString("dateTimeFormatLocalizedCompanity", comment: "date time format for companity")
    
    //AddVoteItemView
    static let addVoteItemRequestText = sdkLocalizedString("addVoteItemRequest", comment: "Please add VoteItem first.")
    
    static let deletePaperAlert = sdkLocalizedString("deletePaperAlert", comment: "Do you want to delete the paper?")
    
    static let selectAll = sdkLocalizedString("all", comment: "Select All")
    
    //SeenUnSeenUserListVC
    static let SeenUnSeenUserListTitleTxt = sdkLocalizedString("SeenUnSeenUserListTitleTxt", comment: "Seen/UnSeen User List")
    static let SeenTabLblTxt = sdkLocalizedString("SeenTabLblTxt", comment: "Seen")
    static let UnSeenTabLblTxt = sdkLocalizedString("UnSeenTabLblTxt", comment: "UnSeen")
    static let RemarksLblTxt = sdkLocalizedString("RemarksLblTxt", comment: "Remarks")
    static let selectedPeopleCounttxt = sdkLocalizedString("selectedPeopleCounttxt", comment: "Selected People Count")
    static let totalPeopleCountTxt = sdkLocalizedString("totalPeopleCountTxt", comment: "total people count")
    static let selectAllBtnTxt = sdkLocalizedString("selectAllBtnTxt", comment: "Select All")
    static let unSelectAllBtnTxt = sdkLocalizedString("unSelectAllBtnTxt", comment: "UnSelect All")
    static let resendBtnTxt = sdkLocalizedString("resendBtnTxt", comment: "resend")
    static let voteText = sdkLocalizedString("voteText", comment: "Vote text")
    static let selectedUserNotifyTxt = sdkLocalizedString("selectedUserNotifyTxt", comment: "Selected user notified")
    
    static let readTxt = sdkLocalizedString("readTxt", comment: "Read")
    static let unReadTxt = sdkLocalizedString("unReadTxt", comment: "Unread")
    static let receiverTxt = sdkLocalizedString("receiverTxt", comment: "Receiver Count")

    static let newPapers = sdkLocalizedString("newPapers", comment: "New Papers")
    static let officialAllTxt = sdkLocalizedString("officialAllTxt", comment: "All")
    
    static let modifiedText = sdkLocalizedString("modifiedTxt", comment: " - modified")
    static let schedule_modifiedText = sdkLocalizedString("schedule_modifiedText", comment: " - schedule modified")
    static let deadline_modifiedText = sdkLocalizedString("deadline_modifiedText", comment: " - deadline modified")
    static let deleteAttachment = sdkLocalizedString("delete_attachment", comment: "delete success")
    
    //ReceiversListVC
    static let ReceiverListTitle = sdkLocalizedString("ReceiverListTitle", comment: "ReceiverList")
    
    //CompanityPhotoRegisterVC
    static let photoUploadWithMissingAttach = sdkLocalizedString("photoUploadWithMissingAttach", comment: "Some photos upload failed")
    static let photoUploadSuccess = sdkLocalizedString("photoUploadSuccess", comment: "photo uploaded successfully")
    static let deletePhotoConfirm = sdkLocalizedString("deletePhotoConfirm", comment: "Are you sure you want to delete photos?")
    
    //ReceiverInterfaceChooseView
    static let ContactListText = sdkLocalizedString("ContactListText", comment: "Contact List")
    static let OrgChartTitleTxt = sdkLocalizedString("OrgChartTitleTxt", comment: "Organization Chart")
    
    static let LogoutConfirmMsg = sdkLocalizedString("LogoutConfirmMsg", comment: "Log out will prevent you from receiving message notifications.\nAre you sure you want to log out?")
    
    
    // ScheduleRegisterView
    static let noEventTitle = sdkLocalizedString("noEventTitle", comment: "No Event Title")
    static let invalidScheduleDate = sdkLocalizedString("invalidScheduleDate", comment: "Invalid Schedule Date")
    static let inputStartDate = sdkLocalizedString("inputStartDate", comment: "Input Start Date")
    static let inputEndDate = sdkLocalizedString("inputEndDate", comment: "Input End Date")
    static let inputStartTime = sdkLocalizedString("inputStartTime", comment: "Input Start Time")
    static let inputEndTime = sdkLocalizedString("inputEndTime", comment: "Input End Time")
    
    static let inputGreaterEndDateTime = sdkLocalizedString("inputGreaterEndDateTime", comment: "Input Greater End Time")
    static let inputGreaterThanCurrentTime = sdkLocalizedString("inputGreaterThanCurrentTime", comment: "Input Greater End Time")
    
    static let attendOptionNotSelected = sdkLocalizedString("attendOptionNotSelected", comment: "Attend Option Not Selected")
    
    static let scheduleInUse = sdkLocalizedString("scheduleInUse", comment: "Already Schedule added")
    
    static let attending = sdkLocalizedString("attending", comment: "attending")
    static let notAttending = sdkLocalizedString("notAttending", comment: "notAttending")
    static let late = sdkLocalizedString("late", comment: "late")
    static let early = sdkLocalizedString("early", comment: "early")
    
    
    static let enterEventTitle = sdkLocalizedString("enterEventTitle", comment: "Enter Event")
    static let allDay = sdkLocalizedString("allDay", comment: "All Day")
    static let chooseAttend = sdkLocalizedString("chooseAttend", comment: "Choose Attend")
    static let enterRemarks = sdkLocalizedString("enterRemarks", comment: "Enter Remarks")
    static let noPlaceText = sdkLocalizedString("noPlaceText", comment: "Place")
    
    static let calenderAccessNotGranted = sdkLocalizedString("calenderAccessNotGranted", comment: "access not granted")
    
    //SelectDepartmentVC
    static let noMembersInDept = sdkLocalizedString("noMembersInDept", comment: "No Members In Dept")
    
    // Companity Login
    static let serverSettingTitle = sdkLocalizedString("serverSettingTitle", comment: "Server connection information")
    static let serverSettingSubtitle = sdkLocalizedString("serverSettingSubtitle", comment: "Please set up connection information.")
    
    // SubModuleTableViewCell
    static let recentAndFavorites = sdkLocalizedString("recentAndFavorites", comment: "Recent And Favorites")
    static let noModulesAvailable = sdkLocalizedString("noModulesAvailable", comment: "No Modules Available")

}

//CreatVote
struct Vote {
    static let option = sdkLocalizedString("Option", comment: "Option")
    static let detailTxtViewPlaceHolderTxt = sdkLocalizedString("VoteDetailPlaceHolderTxt", comment: "vote paper Description PlaceHolder text")
    
    static let voteConfirmTitle = sdkLocalizedString("VoteConfirmTitle", comment: "vote confirmation")
    static let closeVoteConfirmTitle = sdkLocalizedString("CloseVoteConfirmTitle", comment: "vote close confirmation")
    
    static let voteConfirmMsg = sdkLocalizedString("VoteConfirmMsg", comment: "vote confirmation")
    static let closeVoteConfirmMsg = sdkLocalizedString("CloseVoteConfirmMsg", comment: "vote close confirmation")
    
    static let cannotCloseVote = sdkLocalizedString("cannotCloseVote", comment: "vote close not allowed")
    
    static let voteClosed = sdkLocalizedString("voteClosed", comment: "vote closed")
    static let eventClosed = sdkLocalizedString("eventClosed", comment: "event closed")
    static let deadlineCrossed = sdkLocalizedString("deadlineCrossed", comment: "Deadline Crossed")
    static let readOnly_cantVote = sdkLocalizedString("readOnly_cantVote", comment: "read only cant vote")
    static let noTitleInVoteItem = sdkLocalizedString("noTitleInVoteItem", comment: "no Title In VoteItem")
    
    static let voteLimitExceeded = sdkLocalizedString("voteLimitExceeded", comment: "Vote Limit Exceeded")
}

//MARK: Companity
struct FirebaseSignupAndLoginMessages {
    static let emailFieldEmpty = sdkLocalizedString("EmailFieldEmpty", comment: "Email Field Empty")
    static let emailInvalid = sdkLocalizedString("EmailInvalid", comment: "Email Invalid")
    
    static let passwordEmpty = sdkLocalizedString("PasswordEmpty", comment: "Password Empty")
    static let passwordMismatch = sdkLocalizedString("PasswordMismatch", comment: "Password Mismatch")

    static let loginCredentialsWrong = sdkLocalizedString("LoginCredentialsWrong", comment: "Wrong Login Credentials")
    
}

struct CreateWriteMsg {
    static let requestPaperDescription = sdkLocalizedString("RequestPaperDescription", comment: "Request Paper Description")
    static let requestMembers = sdkLocalizedString("RequestMembers", comment: "Request Members")
    static let imageUploadFailed = sdkLocalizedString("ImageUploadFailed", comment: "Image Upload Failed")
    static let serverNotReachable = sdkLocalizedString("ServerNotReachable", comment: "Server Not Reachable")
    static let paperCreateSuccess = sdkLocalizedString("PaperCreateSuccess", comment: "Paper Create Success")
    static let paperCreatedWithMissingAttach = sdkLocalizedString("paperCreatedWithMissingAttach", comment: "Some items upload failed")
    static let createPaperTitleTxt = sdkLocalizedString("createPaperTitleTxt", comment: "create paper title text")
}

struct Feedback {
    //FeedbackEmoBarView
    static let good = sdkLocalizedString("good", comment: "Good feedback!")
    static let confirm = sdkLocalizedString("confirm", comment: "Confirmed feedback!")
    static let celebrate = sdkLocalizedString("celebrate", comment: "Celebrate feedback!")
    static let sad = sdkLocalizedString("sad", comment: "Sad feedback!")
    static let neutral = sdkLocalizedString("neutral", comment: "Neutral feedback!")
}

struct FeedbackDBValue {
    //Feedback Value from Database
    static let good = "Good"
    static let confirm = "Confirm"
    static let celebrate = "Celebrate"
    static let sad = "Sad"
    static let neutral = "Neutral"
}

struct FeedBackValue {
    static let  ALL = 0
    static let  Good = 1
    static let  Confirm = 2
    static let  Celebrate = 3
    static let  Sad = 4
    static let  Neutral = 5
}

struct FeedbackImgSmall {
    //Feedback Icon image name
    static let good = "icon_good_small"
    static let confirm = "icon_check_small"
    static let celebrate = "icon_celebrate_small"
    static let sad = "icon_sad_small"
    static let neutral = "icon_go_small"
}

//For floating action buttons
struct FloatingActionButtonsTitle {
    //Feedback Icon image name
    static let notice = sdkLocalizedString("Notice", comment: "Notice")
    static let create = sdkLocalizedString("Create", comment: "Create")
    static let official = sdkLocalizedString("Official", comment: "Official Board")
    static let vote = sdkLocalizedString("Vote", comment: "Vote")
    static let choose = sdkLocalizedString("Choose", comment: "Choose between two")
    static let schedule = sdkLocalizedString("Schedule", comment: "Schedule Paper")
}

struct MainPaperType {
    //FeedbackEmoBarView
    static let all = sdkLocalizedString("AllPaper", comment: "All papers")
    static let received = sdkLocalizedString("ReceivedPaper", comment: "All received papers")
    static let official = sdkLocalizedString("OfficialPaper", comment: "Official papers")
    static let iWrote = sdkLocalizedString("IWrotePaper", comment: "Self written papers")
    static let hidden = sdkLocalizedString("Hidden", comment: "Hidden")
    static let archive = sdkLocalizedString("Archive", comment: "Archive")
}

struct MainPaperCellAction {
    //FeedbackEmoBarView
    static let archive = sdkLocalizedString("Archive", comment: "Archive")
    static let unArchive = sdkLocalizedString("Unarchive", comment: "Unarchive")
    static let hide = sdkLocalizedString("Hide", comment: "Hide paper")

    static let unhide = sdkLocalizedString("Unhide", comment: "Unhide paper")
    static let copyAndWrite = sdkLocalizedString("CopyAndWrite", comment: "Copy and write")

    static let copyAndCreate = sdkLocalizedString("CopyAndCreate", comment: "Copy and create paper")
    static let replyPaper = sdkLocalizedString("replyPaper", comment: "Reply paper")
    static let edit = sdkLocalizedString("Edit", comment: "Edit paper")
    static let delete = sdkLocalizedString("Delete", comment: "Delete paper")

}

struct AlertTitle {
    static let alert = sdkLocalizedString("Alert", comment: "Title")

    static let yes = sdkLocalizedString("YES", comment: "yes")
    static let ok = sdkLocalizedString("Ok", comment: "ok")
    static let confirm = sdkLocalizedString("ConfirmText", comment: "confirm")

    static let no = sdkLocalizedString("NO", comment: "no")
    static let cancel = sdkLocalizedString("Cancel", comment: "cancel")

    
    static let mapPicker = sdkLocalizedString("MapPicker", comment: "Map picker")
    static let mapAccessMsg = sdkLocalizedString("MapAccessMsg", comment: "Map Access permission")

    
    static let imagePicker = sdkLocalizedString("ImagePicker", comment: "Image picker")
    static let imageAccessMsg = sdkLocalizedString("ImageAccessMsg", comment: "Image Access permission")
    
    static let videoPicker = sdkLocalizedString("VideoPicker", comment: "Video picker")
    static let videoAccessMsg = sdkLocalizedString("VideoAccessMsg", comment: "Video Access permission")
    
    static let noCamera = sdkLocalizedString("NoCamera", comment: "No Camera Title")
    static let noCameraMsg = sdkLocalizedString("NoCameraMsg", comment: "No Camera Message")
    
    static let pleaseWait = sdkLocalizedString("PleaseWait", comment: "Please wait...")
    
    static let videoSaveSuccessMsg = sdkLocalizedString("VideoSaveSuccessMsg", comment: "Video was successfully saved")
    static let videoCorrupt = sdkLocalizedString("VideoCorrupt", comment: "Video corrupt")
    static let videoUnavailableMsg = sdkLocalizedString("VideoUnavailableMsg", comment: "Video unavailable message")
    
    static let officialReceiversDisabled = sdkLocalizedString("officialReceiversDisabled", comment: "Official Paper receivers diabled")
 
}

struct VoteVisibility {
    static let defaultVal = 0
    static let secret = 1
    static let hideVoter = 2
    static let hideCount = 3
}

//Companity DB Node Names
struct CompanityDB {
    struct Companity {
        static let root = "Companity"

        static let photo = "photo"
    }
    
    struct CompanyToHash {
        static let root = "CompanyToHash"
    }
    
    struct MessageReceivers {
        static let root = "MessageReceivers"
    }
    
    struct MessageToVote {
        static let root = "MessageToVote"
        
        static let voteName = "name"
        static let voters = "voters"
    }
    

    struct Papers {
        static let root = "Papers"
        
        static let attachments = "attachments"
        static let sender = "sender"
        static let text = "text"
        
        static let feedback = "feedback"

        static let voteItems = "voteItems"
        static let voteName = "name"
        static let voteCount = "count"
        static let voteLimit = "limit"
        static let voteItemType = "voteItemType"
        static let itemAttachment = "attachment"
        
        static let voteClosingTime = "voteClosingTime"
        static let updateTime = "updateTime"
        static let createdDate = "createdDate"
        
        static let multipleSelection = "multipleSelection"
        static let canAddItem = "canAddItem"
        static let visibilityType = "visibilityType"
        static let hasVoteLimit = "hasVoteLimit"

        static let location = "location"
        static let label = "label"
        static let lat = "lat"
        static let lon = "lon"
        
        static let url = "url"
        static let pageTitle = "pageTitle"
        static let pageUrl = "pageUrl"
        static let pageSnippet = "pageSnippet"
        static let pageThumbnail = "pageThumbnail"
        
        static let pending = "pending"
        
        static let remarks = "Remarks"
        static let remarkScript = "RemarkScript"
    }
    
    struct UserPapers {
        static let root = "UserPapers"
        
        //Paper types
        static let hidden = "hidden"
        static let sendReceive = "sendReceive"
        static let archive = "archive"
        
        //Paper properties
        static let fix = "fix"
        static let official = "official"
        static let receivedTime = "receivedTime"
        static let updateTime = "updateTime"
        static let hash = "hash"
        static let feedback = "feedback"
        static let feedbackSync = "feedbackSync"
        static let voted = "voted"
        static let isVoted = "isVoted"
        static let voteCount = "count"
        
        //Archived Paper properties
        static let rootPaperID = "rootPaperID"
        static let archivedTime = "archivedTime"
        static let paper = "paper"
        static let archivedCount = "archivedCount"
    }
    
    struct Users {
        static let root = "Users"
        
        static let email = "email"
        static let phoneNo = "phoneNo"
        static let userName = "userName"
        static let userPhoto = "userPhoto"
        static let userid = "userId"
        static let userSeq = "userSeq"
    }
    
    struct UserToDevice {
        static let root = "UserToDevice"
        
    }
    
    struct FbToUserKey {
        static let root = "FbToUserKey"
        
    }
    
    struct FIRE_ID_TO_YLW_ID {
         static let root = "FbUidToYlwUid"
    }
    
    struct ElasticKey {
        static let root = "ElasticKey"
    }
    
    struct referencePath {
        static let root = "referencePath"
    }
    
    struct AttachmentRefs {
        static let root = "AttachmentRefs"
    }
}

enum AttachType: Int {
    case image = 1, video = 2, map = 3, url = 4, schedule = 5
}

//Companity Storage folder Names
struct StorageFolder {
    static let photo = "Photo";
    static let thumbnail = "Thumbnail";
}

//Companity DB Node Names
struct CompanityStorage {
        static let attachments = "Attachments"
        static let thumbnail = "Thumbnail"
}

let ImageExtensionList = ["jpg","png"]
let VideoExtensionList = ["mov","mp4"]






