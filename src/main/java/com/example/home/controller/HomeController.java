package com.example.home.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("pageTitle", "(주)제주종합관리 - 건물종합관리 전문기업");
        return "index";
    }

    @GetMapping("/company")
    public String company(Model model) {
        model.addAttribute("pageTitle", "회사소개 -  (주)제주종합관리");
        return "company";
    }

    @GetMapping("/company/greeting")
    public String greeting(Model model) {
        model.addAttribute("pageTitle", "인사말 - (주)제주종합관리");
        return "greeting";
    }

    @GetMapping("/company/organization")
    public String organization(Model model) {
        model.addAttribute("pageTitle", "조직도 - (주)제주종합관리");
        return "organization";
    }

    @GetMapping("/company/directions")
    public String directions(Model model) {
        model.addAttribute("pageTitle", "오시는길 - (주)제주종합관리");
        return "directions";
    }

    @GetMapping("/business")
    public String business(Model model) {
        model.addAttribute("pageTitle", "사업소개 - (주)제주종합관리");
        return "business";
    }

    @GetMapping("/projects")
    public String projects(Model model) {
        model.addAttribute("pageTitle", "주요실적 - (주)제주종합관리");
        return "projects";
    }

    @GetMapping("/process")
    public String process(Model model) {
        model.addAttribute("pageTitle", "진행절차 - (주)제주종합관리");
        return "process";
    }

    @GetMapping("/contact")
    public String contact(Model model) {
        model.addAttribute("pageTitle", "문의하기 - (주)제주종합관리");
        return "contact";
    }
}