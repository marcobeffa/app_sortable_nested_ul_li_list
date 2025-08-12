require "test_helper"

class ListItemsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get list_items_index_url
    assert_response :success
  end

  test "should get show" do
    get list_items_show_url
    assert_response :success
  end

  test "should get new" do
    get list_items_new_url
    assert_response :success
  end

  test "should get create" do
    get list_items_create_url
    assert_response :success
  end

  test "should get edit" do
    get list_items_edit_url
    assert_response :success
  end

  test "should get update" do
    get list_items_update_url
    assert_response :success
  end

  test "should get destroy" do
    get list_items_destroy_url
    assert_response :success
  end
end
