<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Endang Kosasih - Senior Programmer</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <!-- Preloader -->
    <div id="preloader">
        <div class="loader"></div>
    </div>

    <!-- Navigation -->
    <nav class="navbar" id="navbar">
        <div class="nav-container">
            <a href="#home" class="nav-logo">EK<span>.</span></a>
            <div class="nav-menu" id="nav-menu">
                <a href="#home" class="nav-link active">Home</a>
                <a href="#about" class="nav-link">About</a>
                <a href="#skills" class="nav-link">Skills</a>
                <a href="#experience" class="nav-link">Experience</a>
                <a href="#projects" class="nav-link">Projects</a>
                <a href="#education" class="nav-link">Education</a>
                <a href="#contact" class="nav-link">Contact</a>
            </div>
            <div class="nav-toggle" id="nav-toggle">
                <i class="fas fa-bars"></i>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section class="hero" id="home">
        <div class="hero-particles" id="particles"></div>
        <div class="hero-container">
            <div class="hero-content">
                <span class="hero-subtitle">Hello, I'm</span>
                <h1 class="hero-title">Endang Kosasih<span>,</span> S.Kom</h1>
                <div class="hero-typing">
                    <span class="typing-text" id="typing-text"></span>
                    <span class="typing-cursor">|</span>
                </div>
                <p class="hero-description">
                    Senior Programmer with 13+ years of experience in software development, 
                    specializing in .NET, Java Spring Boot, and enterprise application integration.
                </p>
                <div class="hero-buttons">
                    <a href="#contact" class="btn btn-primary">
                        <i class="fas fa-envelope"></i> Contact Me
                    </a>
                    <a href="https://wa.me/6282240672011" target="_blank" class="btn btn-whatsapp">
                        <i class="fab fa-whatsapp"></i> WhatsApp
                    </a>
                    <a href="#experience" class="btn btn-outline">
                        <i class="fas fa-briefcase"></i> My Work
                    </a>
                </div>
                <div class="hero-stats">
                    <div class="stat-item">
                        <span class="stat-number" data-count="13">0</span><span>+</span>
                        <span class="stat-label">Years Experience</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-number" data-count="8">0</span><span>+</span>
                        <span class="stat-label">Projects Completed</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-number" data-count="4">0</span>
                        <span class="stat-label">Companies</span>
                    </div>
                </div>
            </div>
            <div class="hero-image">
                <div class="hero-image-wrapper">
                    <div class="hero-avatar">
                        <img src="assets/img/profile.jpg" alt="Endang Kosasih">
                    </div>
                    <div class="orbit orbit-1"></div>
                    <div class="orbit orbit-2"></div>
                    <div class="orbit orbit-3"></div>
                </div>
            </div>
        </div>
        <div class="scroll-indicator">
            <a href="#about"><i class="fas fa-chevron-down"></i></a>
        </div>
    </section>

    <!-- About Section -->
    <section class="section" id="about">
        <div class="container">
            <div class="section-header">
                <span class="section-subtitle">Get To Know</span>
                <h2 class="section-title">About Me</h2>
            </div>
            <div class="about-grid">
                <div class="about-info">
                    <div class="about-card">
                        <div class="about-card-icon"><i class="fas fa-user"></i></div>
                        <h3>Personal Info</h3>
                        <ul class="about-list">
                            <li><strong>Name:</strong> Endang Kosasih, S.Kom</li>
                            <li><strong>Age:</strong> <?php echo date('Y') - 1989; ?> years old</li>
                            <li><strong>Place of Birth:</strong> Cirebon</li>
                            <li><strong>Date of Birth:</strong> March 29, 1989</li>
                            <li><strong>Gender:</strong> Male</li>
                            <li><strong>Nationality:</strong> Indonesia</li>
                            <li><strong>Religion:</strong> Islam</li>
                            <li><strong>Status:</strong> Married</li>
                        </ul>
                    </div>
                </div>
                <div class="about-description">
                    <div class="about-card">
                        <div class="about-card-icon"><i class="fas fa-laptop-code"></i></div>
                        <h3>Professional Summary</h3>
                        <p>
                            A dedicated Senior Programmer with over 13 years of experience in the IT industry. 
                            Proficient in developing enterprise-level applications using .NET Framework, Java Spring Boot, 
                            and various PHP frameworks. Experienced in SAP integration, CRM applications, REST API development, 
                            and database management across SQL Server, MySQL, PostgreSQL, and Oracle.
                        </p>
                        <p>
                            Currently supporting major clients including PT. Berlian Sistem Informasi (Group Mitsubishi) 
                            and PT. AJ Manulife Indonesia at PT. Asiatek Solusi Indonesia. Strong background in Agile methodology, 
                            team leadership, and project management.
                        </p>
                    </div>
                    <div class="about-card">
                        <div class="about-card-icon"><i class="fas fa-map-marker-alt"></i></div>
                        <h3>Location</h3>
                        <p><i class="fas fa-home"></i> Domicile: Vila Bogor Indah 6 - Bogor</p>
                        <p><i class="fas fa-building"></i> Origin: Cirebon City, West Java</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Skills Section -->
    <section class="section section-dark" id="skills">
        <div class="container">
            <div class="section-header">
                <span class="section-subtitle">What I Know</span>
                <h2 class="section-title">Skills & Expertise</h2>
            </div>
            <div class="skills-grid">
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-desktop"></i></div>
                    <h3>Application Expert</h3>
                    <p>Sales Force, HRIS, SIMRS</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="90%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-tools"></i></div>
                    <h3>Troubleshooting</h3>
                    <p>Hardware & Software</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="85%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-code"></i></div>
                    <h3>Programming Language</h3>
                    <p>JAVA, .Net Core, MVC</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="92%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-mobile-alt"></i></div>
                    <h3>Mobile Application</h3>
                    <p>React Native, Cordova, Flutter</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="80%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-layer-group"></i></div>
                    <h3>Framework PHP/Java</h3>
                    <p>Laravel, CodeIgniter, Spring Boot</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="88%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-database"></i></div>
                    <h3>Database</h3>
                    <p>SQL Server, MySQL, PostgreSQL, Oracle</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="90%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-photo-video"></i></div>
                    <h3>Editing Video & Image</h3>
                    <p>Photoshop, Movie Maker, CorelDraw</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="75%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-chart-bar"></i></div>
                    <h3>Business Intelligence</h3>
                    <p>Microsoft Power BI</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="82%"></div></div>
                </div>
                <div class="skill-card" data-aos="fade-up">
                    <div class="skill-icon"><i class="fas fa-warehouse"></i></div>
                    <h3>Data Warehouse</h3>
                    <p>ETL, SSIS/SSAS</p>
                    <div class="skill-bar"><div class="skill-progress" data-width="85%"></div></div>
                </div>
            </div>
        </div>
    </section>

    <!-- Experience Section -->
    <section class="section" id="experience">
        <div class="container">
            <div class="section-header">
                <span class="section-subtitle">My Journey</span>
                <h2 class="section-title">Work Experience</h2>
            </div>
            <div class="timeline">
                <div class="timeline-item">
                    <div class="timeline-dot"></div>
                    <div class="timeline-content">
                        <div class="timeline-header">
                            <span class="timeline-date">Juni 2021 - Present</span>
                            <span class="timeline-badge">Current</span>
                        </div>
                        <h3>Senior Programmer</h3>
                        <h4><i class="fas fa-building"></i> PT. Asiatek Solusi Indonesia</h4>
                        <p class="timeline-clients"><strong>Support Client:</strong></p>
                        <ul>
                            <li>PT. Berlian Sistem Informasi (Group Mitsubishi)</li>
                            <li>PT. AJ Manulife Indonesia</li>
                        </ul>
                        <p class="timeline-responsibilities"><strong>Responsibilities:</strong></p>
                        <ul>
                            <li>Analysis case and Bug fixing with team member</li>
                            <li>Create new application using .Net framework integrate with SAP, CRM App</li>
                            <li>Create Rest API / Webservice function</li>
                            <li>Custom / Develop existing application using .Net framework and Java Spring Boot</li>
                            <li>Generate function and StoreProc (SQL/Oracle DB)</li>
                            <li>Agile Methodology</li>
                            <li>Sales Force App Enhancement</li>
                        </ul>
                    </div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-dot"></div>
                    <div class="timeline-content">
                        <div class="timeline-header">
                            <span class="timeline-date">Des 2016 - Mei 2021</span>
                        </div>
                        <h3>Senior Technical App</h3>
                        <h4><i class="fas fa-building"></i> PT. Sreeya Sewu Indonesia, Tbk</h4>
                        <ul>
                            <li>Analysis Case with Team Members for Develop/Custom Application Axapta 2009/2012 R3, PHP(Laravel,CI), .Net Core, RoR MVC, CRM</li>
                            <li>Project Manager Data Warehouse with SSIS/SSAS</li>
                            <li>Project Manager TMS with Android Framework</li>
                            <li>Responsible for Team Performance</li>
                            <li>Manage Team Priorities and Assign Work to Team Members</li>
                            <li>Agile Methodology</li>
                            <li>Provides Input Into the Development of Project Management Policies</li>
                            <li>Sales Force Enhancement</li>
                        </ul>
                    </div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-dot"></div>
                    <div class="timeline-content">
                        <div class="timeline-header">
                            <span class="timeline-date">April 2014 - Nov 2016</span>
                        </div>
                        <h3>IT Supervisor & Software Engineer</h3>
                        <h4><i class="fas fa-building"></i> PT. Tosei Engineering Corp Japan</h4>
                        <ul>
                            <li>Develop a Measurement System with VB.NET</li>
                            <li>Develop Applications with C#, PHP (CI, Laravel)</li>
                            <li>Axapta's ERP Programming 2009</li>
                            <li>Receive Complaints from users for Maintenance of Hardware & Software</li>
                            <li>Responsible for Team Performance</li>
                            <li>Manage Team Priorities and Assign Work to Team Members</li>
                            <li>Waterfall Methodology</li>
                        </ul>
                    </div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-dot"></div>
                    <div class="timeline-content">
                        <div class="timeline-header">
                            <span class="timeline-date">Des 2011 - April 2014</span>
                        </div>
                        <h3>Project Coordinator</h3>
                        <h4><i class="fas fa-building"></i> PT. Jasamedika Saranatama</h4>
                        <ul>
                            <li>Develop SIMRS Application</li>
                            <li>Work on Projects According to Deadlines with Team</li>
                            <li>Supervise the Team to Training the Program for User</li>
                            <li>Work with Team for Software & Network Maintenance</li>
                            <li>Receive Program Complaints from Users</li>
                            <li>Responsible for Team Performance</li>
                            <li>Manage Team Priorities and Assign Work to Team Members</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Projects Section -->
    <section class="section section-dark" id="projects">
        <div class="container">
            <div class="section-header">
                <span class="section-subtitle">Portfolio</span>
                <h2 class="section-title">Projects Handled</h2>
            </div>
            <div class="projects-grid">
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-car"></i></div>
                    <div class="project-year">2021</div>
                    <h3>Dealer System Integration</h3>
                    <p class="project-client"><i class="fas fa-users"></i> MMKSI & KTB</p>
                </div>
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-plug"></i></div>
                    <div class="project-year">2021</div>
                    <h3>Rest API Dealer System</h3>
                    <p class="project-client"><i class="fas fa-users"></i> MMKSI & KTB</p>
                </div>
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-database"></i></div>
                    <div class="project-year">2019</div>
                    <h3>Data Warehouse (DWH)</h3>
                    <p class="project-client"><i class="fas fa-users"></i> Sreeya Sewu Indonesia, Tbk</p>
                </div>
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-truck"></i></div>
                    <div class="project-year">2018</div>
                    <h3>Transportation Management System</h3>
                    <p class="project-client"><i class="fas fa-users"></i> Sreeya Sewu Indonesia, Tbk</p>
                </div>
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-globe"></i></div>
                    <div class="project-year">2017</div>
                    <h3>Web Company Profile</h3>
                    <p class="project-client"><i class="fas fa-users"></i> Sreeya Sewu Indonesia, Tbk</p>
                </div>
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-cog"></i></div>
                    <div class="project-year">2015</div>
                    <h3>Face Takasa Measurement System</h3>
                    <p class="project-client"><i class="fas fa-users"></i> Honda Precision Parts Manufacturing (HPPM)</p>
                </div>
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-cogs"></i></div>
                    <div class="project-year">2014</div>
                    <h3>Gear Checker Measurement System</h3>
                    <p class="project-client"><i class="fas fa-users"></i> Musashi Auto Parts, Astra Honda Motor</p>
                </div>
                <div class="project-card">
                    <div class="project-icon"><i class="fas fa-hospital"></i></div>
                    <div class="project-year">2013</div>
                    <h3>Hospital Management System</h3>
                    <p class="project-client"><i class="fas fa-users"></i> Mulyasari Hospital, Sidawangi Hospital</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Education Section -->
    <section class="section" id="education">
        <div class="container">
            <div class="section-header">
                <span class="section-subtitle">Academic Background</span>
                <h2 class="section-title">Education</h2>
            </div>
            <div class="education-grid">
                <div class="education-card">
                    <div class="education-icon"><i class="fas fa-graduation-cap"></i></div>
                    <div class="education-year">2010 - 2011</div>
                    <h3>Bachelor of Information Systems</h3>
                    <h4>STMIK CIC Cirebon</h4>
                    <p class="education-gpa">IPK: 3.17</p>
                </div>
                <div class="education-card">
                    <div class="education-icon"><i class="fas fa-user-graduate"></i></div>
                    <div class="education-year">2007 - 2010</div>
                    <h3>Diploma in Information Management</h3>
                    <h4>STMIK CIC Cirebon</h4>
                    <p class="education-gpa">IPK: 3.19</p>
                </div>
                <div class="education-card">
                    <div class="education-icon"><i class="fas fa-school"></i></div>
                    <div class="education-year">2004 - 2007</div>
                    <h3>Senior High School</h3>
                    <h4>SMAN 7 Cirebon City</h4>
                    <p class="education-gpa"></p>
                </div>
            </div>
        </div>
    </section>

    <!-- Contact Section -->
    <section class="section section-dark" id="contact">
        <div class="container">
            <div class="section-header">
                <span class="section-subtitle">Get In Touch</span>
                <h2 class="section-title">Contact Me</h2>
            </div>
            <div class="contact-grid">
                <div class="contact-info">
                    <div class="contact-card">
                        <div class="contact-card-icon"><i class="fas fa-phone"></i></div>
                        <h3>Phone</h3>
                        <p>082240672011</p>
                    </div>
                    <div class="contact-card">
                        <div class="contact-card-icon"><i class="fas fa-envelope"></i></div>
                        <h3>Email</h3>
                        <p>endangkosasih29@gmail.com</p>
                    </div>
                    <div class="contact-card">
                        <div class="contact-card-icon"><i class="fas fa-map-marker-alt"></i></div>
                        <h3>Address</h3>
                        <p>Vila Bogor Indah 6 - Bogor</p>
                    </div>
                    <div class="contact-card whatsapp-card">
                        <div class="contact-card-icon"><i class="fab fa-whatsapp"></i></div>
                        <h3>WhatsApp</h3>
                        <a href="https://wa.me/6282240672011" target="_blank" class="btn btn-whatsapp-full">
                            <i class="fab fa-whatsapp"></i> Chat via WhatsApp
                        </a>
                    </div>
                </div>
                <div class="contact-form-wrapper">
                    <form action="send_message.php" method="POST" class="contact-form" id="contact-form">
                        <div class="form-group">
                            <input type="text" name="name" id="name" placeholder="Your Name" required>
                            <label for="name"><i class="fas fa-user"></i></label>
                        </div>
                        <div class="form-group">
                            <input type="email" name="email" id="email" placeholder="Your Email" required>
                            <label for="email"><i class="fas fa-envelope"></i></label>
                        </div>
                        <div class="form-group">
                            <input type="text" name="subject" id="subject" placeholder="Subject" required>
                            <label for="subject"><i class="fas fa-tag"></i></label>
                        </div>
                        <div class="form-group">
                            <textarea name="message" id="message" placeholder="Your Message" rows="5" required></textarea>
                            <label for="message"><i class="fas fa-comment-dots"></i></label>
                        </div>
                        <div class="form-buttons">
                            <button type="submit" class="btn btn-primary btn-submit">
                                <i class="fas fa-paper-plane"></i> Send Message
                            </button>
                            <a href="https://wa.me/6282240672011?text=Hello%20Endang%20Kosasih,%20I%20would%20like%20to%20connect%20with%20you." 
                               target="_blank" class="btn btn-whatsapp">
                                <i class="fab fa-whatsapp"></i> Send via WhatsApp
                            </a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <div class="footer-content">
                <div class="footer-logo">EK<span>.</span></div>
                <p>&copy; <?php echo date('Y'); ?> Endang Kosasih. All Rights Reserved.</p>
                <div class="footer-social">
                    <a href="https://wa.me/6282240672011" target="_blank" class="social-link">
                        <i class="fab fa-whatsapp"></i>
                    </a>
                    <a href="mailto:endangkosasih29@gmail.com" class="social-link">
                        <i class="fas fa-envelope"></i>
                    </a>
                </div>
            </div>
        </div>
    </footer>

    <!-- WhatsApp Float Button -->
    <a href="https://wa.me/6282240672011?text=Hello%20Endang%20Kosasih,%20I%20visited%20your%20portfolio%20website%20and%20would%20like%20to%20connect." 
       target="_blank" class="whatsapp-float" id="whatsapp-float">
        <i class="fab fa-whatsapp"></i>
        <span class="whatsapp-tooltip">Chat with me</span>
    </a>

    <!-- Back to Top -->
    <a href="#home" class="back-to-top" id="back-to-top">
        <i class="fas fa-arrow-up"></i>
    </a>

    <script src="assets/js/main.js"></script>
</body>
</html>
