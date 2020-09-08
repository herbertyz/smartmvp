package main

import (
	"database/sql"
	"fmt"
	"github.com/go-sql-driver/mysql"
	"strings"

	"html/template"
	"log"
	"net/http"
)

var (
	err   error
	db    *sql.DB
	templ *template.Template
)

// PageData for html page template
type PageData struct {
	Title string
	QStr  string
	Rows  []RowData
	RCnt  int
}

// RowData data struct for query result
type RowData struct {
	UserID         int
	UserEmail      string
	UserPhone      string
	TimeCompleted  mysql.NullTime
	AbVersion      int
	UtmCampaign    string
	UtmSource      string
	CurrentSavings int
	Location       string
}

func init() {
	templ, err = template.ParseFiles("templates/view.html")
	if err != nil {
		log.Fatalln(err.Error())
	}
}

func main() {
	handleDbConnection()
	http.HandleFunc("/", index)
	http.HandleFunc("/view", leadView)

	// serve specific asset to prevent browsing directory
	http.HandleFunc("/assets/css/tachyons.css", func(res http.ResponseWriter, req *http.Request) {
		http.ServeFile(res, req, "assets/css/tachyons.css")
	})
	http.HandleFunc("/assets/img/keyhole.jpg", func(res http.ResponseWriter, req *http.Request) {
		http.ServeFile(res, req, "assets/img/keyhole.jpg")
	})

	// http.Handle("/assets/", http.FileServer(http.Dir("."))) //serve other files in assets dir
	// http.Handle("/favicon.ico", http.NotFoundHandler())
	fmt.Println("server running on port :8080")
	http.ListenAndServe(":8080", nil)
}

func handleDbConnection() {
	// Create an sql.DB and check for errors
	// db, err = sql.Open("mysql", "dbuser:userpwd@/funnel_data")  // local host on default port 3306
	db, err = sql.Open("mysql", "dbuser:userpwd@tcp(smartdb_1:3306)/funnel_data")  // remote host
	if err != nil {
		panic(err.Error())
	}

	// Test the connection to the database
	err = db.Ping()
	if err != nil {
		panic(err.Error())
	}
}

func index(res http.ResponseWriter, req *http.Request) {
	fmt.Println("Serve static index.html")
	http.ServeFile(res, req, "templates/index.html")
}

func leadView(res http.ResponseWriter, req *http.Request) {
	title := "Smart Viewer for MySQL Data"
	var pd = PageData{Title: title}

	queryStr := "SELECT user_id, user_email, user_phone, time_completed, ab_version, " +
		"utm_campaign, utm_source, current_savings, location " +
		"FROM lead_view "
	q := req.URL.Query()

	// add date constraint
	dateStr := q.Get("date")
	if dateStr == "" {
		log.Println("Required URL Param 'date' is missing")
		http.Error(res, "Required URL Param 'date' is missing", http.StatusInternalServerError)
		return
	}
	queryStr += "WHERE DATE(time_completed)=\"" + dateStr + "\" "

	// display null user or not
	nulluserStr := q.Get("nulluser")
	if !strings.HasPrefix(strings.ToUpper(nulluserStr), "Y") {
		queryStr += "AND user_id != -1 "
	}

	// sorting
	orderStr := q.Get("orderby")
	if orderStr != "" {
		queryStr += "ORDER BY " + orderStr + " "
	}

	// add pagination
	limitStr := q.Get("limit")
	if limitStr != "" {
		queryStr += "LIMIT " + limitStr + " "
	}

	// query
	rows, err := db.Query(queryStr)
	if err != nil {
		log.Println(err)
		http.Error(res, "there was an exec error on following query (check proper usage on http://localhost:8080/\n"+
			queryStr, http.StatusInternalServerError)
		return
	}
	fmt.Println("Run Querry:", queryStr)

	var userID int
	var userEmail string
	var userPhone string
	var timeCompleted mysql.NullTime
	var abVersion int
	var utmCampaign string
	var utmSource string
	var currentSavings int
	var location string

	pd.Rows = make([]RowData, 0)
	pd.QStr = queryStr
	cnt := 0
	for rows.Next() {
		cnt++
		err = rows.Scan(&userID, &userEmail, &userPhone,
			&timeCompleted, &abVersion, &utmCampaign, &utmSource,
			&currentSavings, &location)
		if err != nil {
			log.Println(err)
			http.Error(res, "there was an row conversion error", http.StatusInternalServerError)
			// return
		} else {

			pd.Rows = append(pd.Rows, RowData{
				UserID:         userID,
				UserEmail:      userEmail,
				UserPhone:      userPhone,
				TimeCompleted:  timeCompleted,
				AbVersion:      abVersion,
				UtmCampaign:    utmCampaign,
				UtmSource:      utmSource,
				CurrentSavings: currentSavings,
				Location:       location})

		}
	}
	pd.RCnt = cnt

	fmt.Println("Rows handled:", cnt)
	// fmt.Println("Lead view page", pd)
	templ.Execute(res, pd)
	if err != nil {
		log.Fatalln(err.Error())
	}
}
