package com.example.home.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class ContactController {

    @PostMapping("/contact/submit")
    public String submitContact(
            @RequestParam String name,
            @RequestParam String phone,
            @RequestParam String email,
            @RequestParam String message,
            Model model) {
        model.addAttribute("pageTitle", "문의하기 - (주)제주종합관리");
        model.addAttribute("success", true);
        model.addAttribute("successMessage", "성공적으로 접수 되었습니다.");
        return "contact";
    }
}